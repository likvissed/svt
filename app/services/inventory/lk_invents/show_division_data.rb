module Inventory
  module LkInvents
    # Получить данные по указанному отделу (список РМ, макс. число, список работников отдела).
    class ShowDivisionData < BaseService
      # division - номер отдела
      def initialize(current_user, division)
        @current_user = current_user
        @division = division
        @data = {}
      end

      def run
        load_workplace
        load_users
      rescue RuntimeError
        false
      end

      private

      # Получить рабочие места указанного отдела
      def load_workplace
        @data[:workplaces] = Workplace
                               .includes(:iss_reference_site, :iss_reference_building, :iss_reference_room, :user_iss)
                               .left_outer_joins(:workplace_count, :workplace_type)
                               .select('invent_workplace.*, invent_workplace_type.name as type_name,
invent_workplace_type.short_description')
                               .where('invent_workplace_count.division = ?', @division)
                               .order(:workplace_id)
        authorize @data[:workplaces].first, :load_workplace?

        prepare_workplaces
      end

      def prepare_workplaces
        @data[:workplaces] = @data[:workplaces].as_json(
          include: %i[iss_reference_site iss_reference_building iss_reference_room user_iss]
        ).each { |wp| prepare_to_***REMOVED***_table(wp) }
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
