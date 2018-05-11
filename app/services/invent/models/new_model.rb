module Invent
  module Models
    class NewModel < Invent::ApplicationService
      def initialize
        @data = {}
      end

      def run
        init_model
        load_types

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_model
        data[:model] = Model.new
        data[:model_property_list] = data[:model].model_property_lists.build
      end
    end
  end
end
