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
        @data = IO.popen("php #{Rails.root}/lib/generate_division_report.php #{@division}")
      end

      private

      def prepare_tmp_params
        wp[:workplace_count] = WorkplaceCount.find_by(division: @division)
      end
    end
  end
end
