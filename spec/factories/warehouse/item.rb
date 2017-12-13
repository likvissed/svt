module Warehouse
  FactoryBot.define do
    factory :used_item, class: Item do
      inv_item { create(:item, :with_property_values, type_name: 'monitor') }
      type { inv_item.type }
      model { inv_item.model }
      warehouse_type :returnable
      used true
    end
  end
end
