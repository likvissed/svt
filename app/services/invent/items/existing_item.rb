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

      def find_item
        item = InvItem.left_outer_joins(:inv_type).where(invent_type: { name: @type }).find_by(invent_num: @invent_num)

        if item
          data[:exists] = true
          data[:type] = item.inv_type.short_description
          data[:model] = item.inv_model.try(:item_model) || item.item_model

          load_connection_type(item)
        else
          data[:exists] = false
        end
      end

      def load_connection_type(item)
        prop = item.inv_properties.find_by(name: :connection_type)
        data[:connection_type] = item.inv_property_values.find_by(inv_property: prop).try(:inv_property_list).try(:short_description) || 'Не определен'
      end
    end
  end
end
