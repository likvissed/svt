module Invent
  module Workplaces
    # Загрузить все рабочие места.
    class Index < ApplicationService
      def initialize(params)
        @data = {}
        @draw = params[:draw]
        @start = params[:start]
        @length = params[:length]
        @search = params[:search]
        @init_filters = params[:init_filters]
        @filters = params[:filters]
      end

      def run
        load_workplace
        run_filters if @filters
        limit_records
        prepare_to_render
        load_filters if @init_filters

        true
      end

      private

      def load_workplace
        @workplaces = Workplace
                        .left_outer_joins(:workplace_type, :user_iss)
                        .select('invent_workplace.*, invent_workplace_type.short_description as wp_type')
                        .where('fio LIKE ? OR fio is NULL', "%#{@search[:value]}%")
                        .group(:workplace_id)
      end

      # Отфильтровать полученные данные
      def run_filters
        unless @filters['workplace_count_id'].to_i.zero?
          @workplaces = @workplaces.where(workplace_count_id: @filters['workplace_count_id'])
        end

        unless @filters['status'] == 'all'
          @workplaces = @workplaces.where(status: @filters['status'])
        end

        unless @filters['workplace_type_id'].to_i.zero?
          @workplaces = @workplaces.where(workplace_type_id: @filters['workplace_type_id'])
        end

      end

      # Ограничение выборки взависимости от выбранного пользователем номера страницы.
      def limit_records
        @data[:recordsFiltered] = @workplaces.length
        @workplaces = @workplaces
                        .includes(%i[inv_items iss_reference_site iss_reference_building iss_reference_room user_iss workplace_count])
                        .limit(@length).offset(@start)
      end

      def prepare_to_render
        @data[:data] = @workplaces.as_json(
          include: %i[inv_items iss_reference_site iss_reference_building iss_reference_room user_iss workplace_count]
        ).each do |wp|
          wp['location'] = wp_location_string(wp)
          wp['responsible'] = wp['user_iss'] ? wp['user_iss']['fio'] : 'Ответственный не найден'
          wp['status'] = Workplace.translate_enum(:status, wp['status'])
          wp['division'] = wp['workplace_count']['division']
          wp['count'] = wp['inv_items'].count

          wp.delete('inv_items')
          wp.delete('workplace_count')
          wp.delete('iss_reference_site')
          wp.delete('iss_reference_building')
          wp.delete('iss_reference_room')
          wp.delete('user_iss')
        end

        @data[:draw] = @draw
        @data[:recordsTotal] = Workplace.count
      end

      # Загрузить данные для фильтров
      def load_filters
        @data[:filters] = {}
        @data[:filters][:divisions] = WorkplaceCount.select(:workplace_count_id, :division).order('CAST(division AS SIGNED)')
        @data[:filters][:statuses] = statuses
        @data[:filters][:types] = WorkplaceType.select(:workplace_type_id, :short_description)
      end
    end
  end
end
