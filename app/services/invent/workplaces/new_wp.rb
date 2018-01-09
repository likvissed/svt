module Invent
  module Workplaces
    class NewWp < BaseService
      def initialize
        @data = {}
      end

      def run
        load_properties
        load_divisions

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      def load_properties
        properties = LkInvents::InitProperties.new
        return data[:prop_data] = properties.data if properties.run

        raise 'Ошибка сервиса LkInvents::InitProperties'
      end

      def load_divisions
        data[:divisions] = WorkplaceCount.select(:workplace_count_id, :division)
      end
    end
  end
end
