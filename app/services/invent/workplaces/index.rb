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
                        .left_outer_joins(:workplace_type)
                        .select('invent_workplace.*, invent_workplace_type.short_description as wp_type')
                        .group(:workplace_id)
        run_filters if params[:filters]
      end

      # Ограничение выборки взависимости от выбранного пользователем номера страницы.
      def limit_records
        data[:recordsFiltered] = @workplaces.length
        @workplaces = @workplaces
                        .includes(%i[items iss_reference_site iss_reference_building iss_reference_room user_iss workplace_count])
                        .order(workplace_id: :desc).limit(params[:length]).offset(params[:start])
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
      end

      # Загрузить данные для фильтров
      def load_filters
        data[:filters] = {}
        data[:filters][:divisions] = policy_scope(WorkplaceCount).select(:workplace_count_id, :division).order('CAST(division AS SIGNED)')
        data[:filters][:statuses] = workplace_statuses
        data[:filters][:types] = WorkplaceType.select(:workplace_type_id, :short_description)
        data[:filters][:buildings] = IssReferenceBuilding
                                       .select('iss_reference_sites.name as site_name, iss_reference_buildings.*')
                                       .left_outer_joins(:iss_reference_site)
        data[:filters][:priorities] = item_priorities
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
