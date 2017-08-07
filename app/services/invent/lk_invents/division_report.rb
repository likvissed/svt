module Invent
  module LkInvents
    # Класс создает файл, содержащий список РМ отдела
    class DivisionReport < BaseService
      attr_reader :wp

      def initialize(division)
        @division = division
        @wp = {}
      end

      def run
        prepare_tmp_params
        @data = IO.popen("php #{Rails.root}/lib/generate_division_report.php '#{wp.to_json}'")
      end

      private

      def prepare_tmp_params
        wp[:workplace_count] = WorkplaceCount.find_by(division: @division)
        wp[:workplaces] = wp[:workplace_count].workplaces
                            .includes(
                              :iss_reference_site,
                              :iss_reference_building,
                              :iss_reference_room,
                              :workplace_type,
                              :user_iss,
                              :inv_items
                            )
                            .where(status: :confirmed)
                            .as_json(include: %i[iss_reference_site iss_reference_building iss_reference_room workplace_type user_iss inv_items])
      end
    end
  end
end