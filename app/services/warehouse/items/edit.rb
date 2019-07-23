module Warehouse
  module Items
    class Edit < Warehouse::ApplicationService
      def initialize(item_id)
        @item_id = item_id

        super
      end

      def run
        data[:property_values_attributes] = []
        data[:type] = {}
        data[:type][:properties] = []

        find_item
        @item.item_property_values.present? ? load_property_value : load_property

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        @item = Item.find(@item_id)
      end

      def load_property_value
        @item.item_property_values.joins(:property).merge(Invent::Property.order(:property_order)).each do |prop_v|
          data[:property_values_attributes].push(prop_v)
          data[:type][:properties].push(prop_v.property)
        end
      end

      # Если связи с property_value нет, то загружаем стандартные свойства

      def load_property
        # Получить константу, содержащую необходимые свойства ПК
        data[:file_depending] = Invent::Property::FILE_DEPENDING

        @item.inv_type.property_to_types.each do |prop|
          # отбрасываем значения Property.name, не входящих в диапазон констант
          next unless data[:file_depending].include?(prop.property.name)

          data[:property_values_attributes].push(property_id: prop.property_id, value: '')
          data[:type][:properties].push(prop.property)
        end
      end
    end
  end
end
