module Warehouse
  FactoryBot.define do
    factory :item_property_value, class: ItemPropertyValue do
      warehouse_property_value_id nil
      warehouse_item_id nil
      property_id nil
      value ''
    end
  end
end
