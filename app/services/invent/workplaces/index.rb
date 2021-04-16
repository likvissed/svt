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
                        .left_outer_joins(:workplace_type, :user_iss)
                        .select('
                          invent_workplace.*,
                          invent_workplace_type.short_description as wp_type,
                          user_iss.fio as responsible
                        ')
                        .group(:workplace_id)

        run_filters if params[:filters]
      end

      # Ограничение выборки взависимости от выбранного пользователем номера страницы.
      def limit_records
        data[:recordsFiltered] = @workplaces.length
        @workplaces = @workplaces
                        .includes(%i[items iss_reference_site iss_reference_building iss_reference_room workplace_count attachments])
                        .limit(params[:length]).offset(params[:start]).order(order_data)
      end

      def order_data
        name = %w[workplace_id responsible].find { |el| order['name'] == el }
        type = order['type'] == 'desc' ? 'desc' : 'asc'
        "#{name} #{type}"
      end

      def order
        JSON.parse(params[:sort])
      end

      def prepare_to_render
        data[:data] = @workplaces.as_json(
          include: %i[items iss_reference_site iss_reference_building iss_reference_room workplace_count attachments]
        ).each do |wp|
          wp['location'] = wp_location_string(wp)
          wp['responsible'] ||= 'Ответственный не найден'
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
          wp.delete('user_iss')
        end
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
