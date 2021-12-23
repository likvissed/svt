module Invent
  module Workplaces
    # Загрузить все рабочие места.
    class Index < BaseService
      def initialize(current_user, params)
        @current_user = current_user
        @params = params

        super
      end

      def run
        load_workplace
        limit_records
        prepare_to_render
        load_filters if need_init_filters?

        broadcast_requests

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_workplace
        data[:recordsTotal] = Workplace.count
        @workplaces = policy_scope(Workplace)
                        .left_outer_joins(:workplace_type)
                        .select('
                          invent_workplace.*,
                          invent_workplace_type.short_description as wp_type
                        ')
                        .group(:workplace_id)

        run_filters if params[:filters]
      end

      # Ограничение выборки взависимости от выбранного пользователем номера страницы.
      def limit_records
        data[:recordsFiltered] = @workplaces.length
        @workplaces = @workplaces
                        .includes(%i[items iss_reference_site iss_reference_building iss_reference_room workplace_count attachments])
                        .limit(params[:length]).offset(params[:start])

        @workplaces = @workplaces.order(order_workplace_id) if order['name'] == 'workplace_id'
      end

      def order_workplace_id
        type = order['type'] == 'desc' ? 'desc' : 'asc'
        "workplace_id #{type}"
      end

      def order_responsible
        data[:data] = data[:data].sort_by { |wp| wp['responsible'] }
        data[:data] = order['type'] == 'asc' ? data[:data] : data[:data].reverse
      end

      def order
        JSON.parse(params[:sort])
      end

      def prepare_to_render
        # Массив всех пользователей на одной странице
        find_employees_page

        data[:data] = @workplaces.as_json(
          include: %i[items iss_reference_site iss_reference_building iss_reference_room workplace_count attachments]
        ).each do |wp|
          wp['location'] = wp_location_string(wp)
          wp['responsible'] = fio_employee(wp).presence || 'Ответственный не найден'
          wp['label_status'] = label_status(wp['status'])
          # wp['status'] = Workplace.translate_enum(:status, wp['status'])
          wp['division'] = wp['workplace_count']['division']
          wp['count_items'] = wp['items'].count
          wp['attachments'].each { |att| att['filename'] = att['document'].file.nil? ? 'Файл отсутствует' : att['document'].identifier }
          wp['count_attachments'] = wp['attachments'].count

          wp.delete('items')
          wp.delete('workplace_count')
          wp.delete('iss_reference_site')
          wp.delete('iss_reference_building')
          wp.delete('iss_reference_room')
        end

        # Применить сортировку по ФИО ответственного
        data[:data] = order_responsible if order['name'] == 'responsible'
      end

      def label_status(status)
        case status
        when 'confirmed'
          label_class = 'label-success'
        when 'pending_verification'
          label_class = 'label-warning'
        when 'disapproved'
          label_class = 'label-danger'
        when 'freezed'
          label_class = 'label-primary'
        when 'temporary'
          label_class = 'label-info'
        end

        "<span class='label #{label_class}'>#{Workplace.translate_enum(:status, status)}</span>"
      end

      def load_properties
        properties = LkInvents::InitProperties.new(@current_user)
        return data[:prop_data] = properties.data if properties.run

        raise 'Ошибка сервиса LkInvents::InitProperties'
      end
    end
  end
end
