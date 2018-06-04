module Invent
  module Workplaces
    # Загрузить все рабочие места.
    class Index < BaseService
      def initialize(current_user, params)
        @current_user = current_user
        @start = params[:start]
        @length = params[:length]
        @init_filters = params[:init_filters] == 'true'
        @conditions = JSON.parse(params[:filters]) if params[:filters]

        super
      end

      def run
        load_workplace
        limit_records
        prepare_to_render
        load_filters if @init_filters

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_workplace
        @workplaces = policy_scope(Workplace)
                        .left_outer_joins(:workplace_type)
                        .select('invent_workplace.*, invent_workplace_type.short_description as wp_type')
                        .group(:workplace_id)
        run_filters if @conditions
      end

      # Отфильтровать полученные данные
      def run_filters
        @workplaces = @workplaces.left_outer_joins(:user_iss).where('fio LIKE ?', "%#{@conditions['fullname']}%") if @conditions['fullname'].present?
        @workplaces = @workplaces.left_outer_joins(:items).where('invent_num LIKE ?', "%#{@conditions['invent_num']}%") if @conditions['invent_num'].present?
        @workplaces = @workplaces.where(workplace_count_id: @conditions['workplace_count_id']) unless @conditions['workplace_count_id'].to_i.zero?
        @workplaces = @workplaces.where(status: @conditions['status']) if @conditions.has_key?('status') && @conditions['status'] != 'all'
        @workplaces = @workplaces.where(workplace_type_id: @conditions['workplace_type_id']) unless @conditions['workplace_type_id'].to_i.zero?
        @workplaces = @workplaces.where(workplace_id: @conditions['workplace_id']) unless @conditions['workplace_id'].to_i.zero?
      end

      # Ограничение выборки взависимости от выбранного пользователем номера страницы.
      def limit_records
        data[:recordsFiltered] = @workplaces.length
        @workplaces = @workplaces
                        .includes(%i[items iss_reference_site iss_reference_building iss_reference_room user_iss workplace_count])
                        .order(workplace_id: :desc).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @workplaces.as_json(
          include: %i[items iss_reference_site iss_reference_building iss_reference_room user_iss workplace_count]
        ).each do |wp|
          wp['location'] = wp_location_string(wp)
          wp['responsible'] = wp['user_iss'] ? wp['user_iss']['fio'] : 'Ответственный не найден'
          wp['label_status'] = label_status(wp['status'])
          # wp['status'] = Workplace.translate_enum(:status, wp['status'])
          wp['division'] = wp['workplace_count']['division']
          wp['count'] = wp['items'].count

          wp.delete('items')
          wp.delete('workplace_count')
          wp.delete('iss_reference_site')
          wp.delete('iss_reference_building')
          wp.delete('iss_reference_room')
          wp.delete('user_iss')
        end

        @data[:recordsTotal] = Workplace.count
      end

      # Загрузить данные для фильтров
      def load_filters
        data[:filters] = {}
        data[:filters][:divisions] = policy_scope(WorkplaceCount).select(:workplace_count_id, :division).order('CAST(division AS SIGNED)')
        data[:filters][:statuses] = workplace_statuses
        data[:filters][:types] = WorkplaceType.select(:workplace_type_id, :short_description)
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
        end

        "<span class='label #{label_class}'>#{Workplace.translate_enum(:status, status)}</span>"
      end
    end
  end
end
