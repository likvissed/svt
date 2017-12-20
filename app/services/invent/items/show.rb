module Invent
  module Items
    # Загрузить данные по указанной технике
    class Show < ApplicationService
      def initialize(item_id)
        @item_id = item_id
      end

      def run
        load_item
        prepare_to_edit_item(data)

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def load_item
        @data = InvItem
                  .includes(inv_property_values: :inv_property)
                  .find(@item_id)
                  .as_json(include: { inv_property_values: { include: :inv_property } })
      end

      def prepare_to_edit_item(item)
        item['id'] = item['item_id']
        item['inv_property_values_attributes'] = item['inv_property_values']

        item.delete('item_id')
        item.delete('inv_property_values')

        item['inv_property_values_attributes'].each do |prop_val|
          prop_val['id'] = prop_val['property_value_id']

          # Для пустых значений с типом list и list_plus установить значение = -1 (Это автоматически выберет строчку
          # "Выбрать из списка")
          if %w[list list_plus].include?(prop_val['inv_property']['property_type']) &&
            prop_val['property_list_id'].zero? && prop_val['value'].empty?
            prop_val['property_list_id'] = -1
          end

          prop_val.delete('inv_property')
          prop_val.delete('property_value_id')
        end
      end
    end
  end
end
