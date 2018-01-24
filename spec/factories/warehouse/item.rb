module Warehouse
  FactoryBot.define do
    factory :used_item, class: Item do
      # inv_item { create(:item, :with_property_values, type_name: 'monitor') }
      # type { inv_item.type }
      # model { inv_item.model }
      warehouse_type :returnable
      used true

      after(:build) do |item, ev|
        if item.inv_item
          item.type ||= item.inv_item.type
          item.model ||= item.inv_item.model
        end
      end
    end
  end
end
