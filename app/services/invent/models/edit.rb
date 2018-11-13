module Invent
  module Models
    class Edit < BaseService
      def initialize(model_id)
        @id = model_id

        super
      end

      def run
        find_model
        load_types
        prepare_to_render

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_model
        data[:model] = Model.find(@id).as_json(include: :model_property_lists)
        data[:model_property_list] = ModelPropertyList.new
      end

      def prepare_to_render
        data[:model]['model_property_lists_attributes'] = data[:model]['model_property_lists']
        data[:model]['model_property_lists_attributes'].each do |prop_list|
          prop_list['id'] = prop_list['model_property_list_id']
          prop_list.delete('model_property_list_id')
        end
        data[:model].delete('model_property_lists')
      end
    end
  end
end
