module Warehouse
  class PropertyValue < BaseWarehouse
    self.primary_key = 'warehouse_property_value_id'
    self.table_name = 'warehouse_property_value'

    belongs_to :item, foreign_key: 'warehouse_item_id', optional: false
    belongs_to :property, class_name: 'Invent::Property', foreign_key: 'property_id', optional: false
  end
end
