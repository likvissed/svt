module Invent
  module Models
    class NewModel < BaseService
      def initialize
        super
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

        data[:property_list_not_fixed] = PropertyList.find_by(value: 'not_fixed')
        data[:model_property_list] = data[:model].model_property_lists.build
      end
    end
  end
end
