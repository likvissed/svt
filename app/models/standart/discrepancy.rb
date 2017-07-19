module Standart
  class Discrepancy < BaseStandart
    belongs_to :inv_item, class_name: 'Invent::InvItem', foreign_key: 'item_id'
    belongs_to :inv_property_value, class_name: 'Invent::InvPropertyValue', foreign_key: 'property_value_id', optional: true

    enum event: { add: 0, change: 1, remove: 2 }
  end
end
