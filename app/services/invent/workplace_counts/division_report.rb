module Invent
  module WorkplaceCounts
    # Создать файл, содержащий список РМ отдела
    class DivisionReport < ApplicationService
      def initialize(current_user, division)
        @current_user = current_user
        @division = division

        super
      end

      def run
        find_division

        report = Rails.root.join('lib', 'generate_division_report.php')
        command = "php #{report} #{Rails.env} #{@division}"
        @data = IO.popen(command)

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_division
        @workplace_count = WorkplaceCount.find_by(division: @division)
        authorize @workplace_count, :generate_pdf?
      end
    end
  end
end
