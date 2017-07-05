module Inventory
  module Workplaces
    # Загрузить все рабочие места.
    class Index < ApplicationService
      # init_filters- флаг, определяющий, нужно ли загрузить данные для фильтров.
      # filters - объект, содержащий выбранные фильтры.
      def initialize(init_filters = false, filters = false)
        @data = {}
        @init_filters = init_filters
        @filters = filters
      end
      
      def run
        load_workplace
        run_filters if @filters
        prepare_to_render
        load_filters if @init_filters
        
        true
      end

      private
# .left_outer_joins(:workplace_count)
      def load_workplace
        @workplaces = Workplace
                        .includes(:iss_reference_site, :iss_reference_building, :iss_reference_room, :user_iss, :workplace_count)
                        .left_outer_joins(:workplace_type)
                        .left_outer_joins(:inv_items)
                        .select('invent_workplace.*, invent_workplace_type.short_description as wp_type, 
count(invent_item.item_id) as count')
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

      def prepare_to_render
        @data[:workplaces] = @workplaces.as_json(
          include: %i[iss_reference_site iss_reference_building iss_reference_room user_iss workplace_count]
        ).each do |wp|
          wp['location'] = wp_location_string(wp)
          wp['responsible'] = wp['user_iss']['fio']
          wp['status'] = Workplace.translate_enum(:status, wp['status'])
          wp['division'] = wp['workplace_count']['division']

          wp.delete('workplace_count')
          wp.delete('iss_reference_site')
          wp.delete('iss_reference_building')
          wp.delete('iss_reference_room')
          wp.delete('user_iss')
        end
      end
      
      # Загрузить данные для фильтров
      def load_filters
        @data[:filters] = {}
        @data[:filters][:divisions] = WorkplaceCount.select(:workplace_count_id, :division)
        @data[:filters][:statuses] = statuses
        @data[:filters][:types] = WorkplaceType.select(:workplace_type_id, :short_description)
      end
    end
  end
end
