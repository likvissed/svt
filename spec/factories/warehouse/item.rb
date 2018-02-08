module Warehouse
  FactoryBot.define do
    factory :used_item, class: Item do
      warehouse_type :with_invent_num
      used true
      count 0
      count_reserved 0

      after(:build) do |item, ev|
        # Если не задан тип и модель
        if !item.item_type && !item.item_model
          item.inv_item ||= create(:item, :with_property_values, type_name: 'monitor')
        end

        if item.inv_item
          item.type ||= item.inv_item.type
          item.model ||= item.inv_item.model
        end
      end
    end

    factory :new_item, class: Item do
      warehouse_type :with_invent_num
      used false
      inv_item nil
    end
  end
end
