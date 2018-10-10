module Warehouse
  FactoryBot.define do
    factory :supply, class: Supply do
      name 'Поставка'
      supplyer 'Поставщик'
      date Time.now

      transient do
        without_operations false
        skip_calculate_invent_nums false
      end

      trait :without_operations do
        without_operations true
      end

      after(:build) do |supply, ev|
        if supply.operations.empty? && !ev.without_operations
          item = Item.find_or_initialize_by(item_type: 'Клавиатура', item_model: 'ASUS') do |item|
            item.warehouse_type = :without_invent_num
            item.used = false
            item.count = 20
          end
          # item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'Клавиатура', item_model: 'ASUS', count: 0)
          supply.operations << build(:supply_operation, item: item, shift: 20)

          type = Invent::Type.find_by(name: :monitor)
          model = type.models.last

          item = Item.find_or_initialize_by(invent_type_id: type.type_id, invent_model_id: model.model_id) do |item|
            item.warehouse_type = :with_invent_num
            item.item_type = type.short_description
            item.item_model = model.item_model
            item.used = false
            item.invent_num_start = 111
            item.invent_num_end = 120
            item.count = 10
          end
          # item = build(:new_item, invent_type_id: type.type_id, invent_model_id: model.model_id, item_type: type.short_description, item_model: model.item_model, count: 0)
          supply.operations << build(:supply_operation, item: item, shift: 10, skip_calculate_invent_nums: ev.skip_calculate_invent_nums)
        end
      end
    end
  end
end
