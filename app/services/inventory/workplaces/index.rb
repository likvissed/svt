module Inventory
  module Workplaces
    # Загрузить все рабочие места.
    class Index < ApplicationService
      # init_filters- флаг, определяющий, нужно ли загрузить данные для фильтров.
      # filters - объект, содержащий выбранные фильтры.
      def initialize(init_filters = false, filters)
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

      def load_workplace
        @workplaces = Workplace
                        .includes(:iss_reference_site, :iss_reference_building, :iss_reference_room, :user_iss)
                        .left_outer_joins(:workplace_type)
                        .left_outer_joins(:workplace_count)
                        .left_outer_joins(:inv_items)
                        .select('invent_workplace.*, invent_workplace_count.division, invent_workplace_type
.short_description as wp_type, count(invent_item.item_id) as count')
                        .group(:workplace_id)
      end
      
      # Отфильтровать полученные данные
      def run_filters
        unless @filters['workplace_count_id'].to_i.zero?
          @workplaces = @workplaces.where(workplace_count_id: @filters['workplace_count_id'])
        end
      end

      def prepare_to_render
        @data[:workplaces] = @workplaces.as_json(
          include: %i[iss_reference_site iss_reference_building iss_reference_room user_iss]
        ).each do |wp|
          wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']},
комн. #{wp['iss_reference_room']['name']}"
          wp['responsible'] = wp['user_iss']['fio']
          wp['status'] = Workplace.translate_enum(:status, wp['status'])

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
      end
    end
  end
end
