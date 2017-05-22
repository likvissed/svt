module Inventory
  module LkInvents
    # Получить данные по указанному отделу (список РМ, макс. число, список работников отдела).
    # division - отдел
    class ShowDivisionData
      attr_reader :data

      def initialize(division)
        @division = division
        @data = {}
      end

      def run
        load_workplace
        load_users
      rescue Exception => e
        Rails.logger.info e.inspect
        Rails.logger.info e.backtrace.inspect
        false
      end

      private

      # Получить рабочие места указанного отдела
      def load_workplace
        @data[:workplaces] = Workplace
                  .includes(:iss_reference_site, :iss_reference_building, :iss_reference_room, :user_iss)
                  .left_outer_joins(:workplace_count, :workplace_type)
                  .select('invent_workplace.*, invent_workplace_type.name as type_name, invent_workplace_type
.short_description')
                  .where('invent_workplace_count.division = ?', @division)
                  .order(:workplace_id)

        prepare_to_***REMOVED***_table
      end

      def prepare_to_***REMOVED***_table
        @data[:workplaces] = @data[:workplaces].as_json(
          include: %i[iss_reference_site iss_reference_building iss_reference_room user_iss]
        ).each do |wp|
          wp['status'] = Workplace.translate_enum(:status, wp['status'])
          wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']},
комн. #{wp['iss_reference_room']['name']}"
          wp['fio'] = wp['user_iss']['fio_initials']
          wp['user_tn'] = wp['user_iss']['tn']
          wp['duty'] = wp['user_iss']['duty']

          wp.delete('iss_reference_site')
          wp.delete('iss_reference_building')
          wp.delete('iss_reference_room')
          wp.delete('user_iss')
        end
      end

      # Получить список работников указанного отдела.
      def load_users
        @data[:users] = UserIss
                          .select(:id_tn, :fio)
                          .where(dept: @division)
      end
    end
  end
end
