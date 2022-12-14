module Invent
  module LkInvents
    # Создать файл, содержащий список РМ отдела
    class DivisionReport < BaseService
      attr_reader :wp

      def initialize(division)
        @division = division
        @wp = {}
      end

      def run
        prepare_tmp_params
        report = Rails.root.join('lib', 'generate_division_report.php')

        UsersReference.new_token_hr

        command = "php #{report} #{Rails.env} #{@division} #{Rails.cache.read('token_hr')} #{ENV['USERS_REFERENCE_URI_SEARCH']}"
        @data = IO.popen(command)

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def prepare_tmp_params
        wp[:workplace_count] = WorkplaceCount.find_by(division: @division)
      end
    end
  end
end
