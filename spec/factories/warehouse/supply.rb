module Warehouse
  FactoryBot.define do
    factory :supply, class: Supply do
      name { 'Поставка' }
      supplyer { 'Поставщик' }
      date { Time.zone.now }

      transient do
        without_operations { false }
        skip_calculate_invent_nums { false }
      end

      trait :without_operations do
        without_operations { true }
      end

      after(:build) do |supply, ev|
        if supply.operations.empty? && !ev.without_operations
          item = Item.find_or_initialize_by(item_type: 'Клавиатура', item_model: 'ASUS') do |i|
            i.warehouse_type = :without_invent_num
            i.status = :non_used
            i.count = 20
          end
          # item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'Клавиатура', item_model: 'ASUS', count: 0)
          supply.operations << build(:supply_operation, item: item, shift: 20)

          type = Invent::Type.find_by(name: :monitor)
          model = type.models.last

          item = Item.find_or_initialize_by(invent_type_id: type.type_id, invent_model_id: model.model_id) do |i|
            i.warehouse_type = :with_invent_num
            i.item_type = type.short_description
            i.item_model = model.item_model
            i.status = :non_used
            i.invent_num_start = 111
            i.invent_num_end = 120
            i.count = 10
          end
          # item = build(:new_item, invent_type_id: type.type_id, invent_model_id: model.model_id, item_type: type.short_description, item_model: model.item_model, count: 0)
          supply.operations << build(:supply_operation, item: item, shift: 10, skip_calculate_invent_nums: ev.skip_calculate_invent_nums)
        end
      end
    end
  end
end
