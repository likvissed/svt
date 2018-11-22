module Invent
  module Items
    # Проверить, существует ли указанная техника
    class ExistingItem < ApplicationService
      def initialize(type, invent_num)
        @type = type
        @invent_num = invent_num
        @data = {}
      end

      def run
        find_item

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        item = Item.left_outer_joins(:type).where(invent_type: { name: @type }).find_by(invent_num: @invent_num)

        if item
          data[:exists] = true
          data[:type] = item.type.short_description
          data[:model] = item.full_item_model

          load_connection_type(item)
        else
          data[:exists] = false
        end
      end

      def load_connection_type(item)
        prop = item.properties.find_by(name: :connection_type)
        data[:connection_type] = item.property_values.find_by(property: prop).try(:property_list).try(:short_description) || 'Не определен'
      end
    end
  end
end
