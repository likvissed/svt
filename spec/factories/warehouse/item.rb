module Warehouse
  FactoryBot.define do
    factory :used_item, class: Item do
      warehouse_type :with_invent_num
      used true
      count 1
      count_reserved 0

      after(:build) do |item, ev|
        item.item_type = item.inv_type.short_description if item.inv_type
        item.item_model = item.inv_model.item_model if item.inv_model

        # Если не задан тип и модель
        if !item.item_type && !item.item_model && item.warehouse_type.to_s != 'without_invent_num'
          item.inv_item ||= create(:item, :with_property_values, type_name: 'monitor')
        end

        if item.inv_item
          item.inv_type ||= item.inv_item.type
          item.inv_model ||= item.inv_item.model
        end

        if item.warehouse_type.to_s == 'without_invent_num' && !item.item_type && !item.item_model
          item.item_type = 'CD'
          item.item_model = 'ASUS'
        end
      end
    end

    factory :new_item, parent: :used_item, class: Item do
      warehouse_type :with_invent_num
      used false
      inv_item nil

      after(:build) do |item, ev|
        if item.warehouse_type.to_s == 'without_invent_num' && !item.item_type && !item.item_model
          item.item_type = 'CD'
          item.item_model = 'ASUS'
        end
      end
    end
  end
end
