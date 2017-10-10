module Invent
  module Workplaces
    class NewWp < ApplicationService
      def initialize
        @data = {}
      end

      def run
        load_properties
        load_divisions

        true
      rescue RuntimeError
        false
      end

      def load_properties
        properties = LkInvents::InitProperties.new
        return data[:prop_data] = properties.data if properties.run
        raise 'abort'
      end

      def load_divisions
        data[:divisions] = WorkplaceCount.select(:workplace_count_id, :division)
      end
    end
  end
end
