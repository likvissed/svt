module Standard
  class Discrepancy < BaseStandard
    belongs_to :item, class_name: 'Invent::Item', foreign_key: 'item_id'
    belongs_to :property_value, class_name: 'Invent::PropertyValue', foreign_key: 'property_value_id', optional: true

    enum event: { add: 0, change: 1, remove: 2 }
  end
end
