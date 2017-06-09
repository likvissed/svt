module Inventory
  module Workplaces
    # Загрузить все рабочие места.
    class Index < ApplicationService
      def run
        load_workplace
        prepare_to_render
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

      def prepare_to_render
        @data = @workplaces.as_json(
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
    end
  end
end
