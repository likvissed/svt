module Invent
  module Workplaces
    class NewWp < BaseService
      def initialize(current_user)
        @current_user = current_user
        @data = {}
      end

      def run
        init_workplace
        load_properties
        load_divisions

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_workplace
        wp = Workplace.new
        authorize wp, :new?
      end

      def load_properties
        properties = LkInvents::InitProperties.new
        return data[:prop_data] = properties.data if properties.run

        raise 'Ошибка сервиса LkInvents::InitProperties'
      end

      def load_divisions
        data[:divisions] = WorkplaceCount.select(:workplace_count_id, :division).sort_by { |obj| obj.division.to_i }
      end
    end
  end
end
