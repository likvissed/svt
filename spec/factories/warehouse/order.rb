module Warehouse
  FactoryBot.define do
    factory :order, class: Order do
      inv_workplace nil
      creator_id_tn ***REMOVED***
      # validator_id_tn 5336
      operation :in
      status 'processing'
      consumer_dept { inv_workplace.try(:division) }
      comment ''
      skip_validator true

      transient do
        without_operations false
      end

      trait :without_operations do
        without_operations true
      end

      trait :default_workplace do
        inv_workplace { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      end

      after(:build) do |order, ev|
        order.creator_fio = order.creator_id_tn ? UserIss.find(order.creator_id_tn).fio : ''
        order.validator_fio = order.validator_id_tn ? UserIss.find(order.validator_id_tn).fio : ''

        if order.operation.to_s == 'in'
          if order.operations.empty? && !ev.without_operations
            if order.inv_workplace
              inv_item = order.inv_workplace.items.first
              item = build(:used_item, inv_item: inv_item)
              order.operations << build(:order_operation, item: item, inv_items: [inv_item])
            else
              order.operations << build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK')
              order.operations << build(:order_operation, item_type: 'Мышь', item_model: 'Logitech')
            end
          end
        elsif order.operation.to_s == 'out'
          order.inv_workplace ||= create(:workplace_pk, disabled_filters: true)

          if order.operations.empty? && !ev.without_operations
            item1 = Item.find_by(item_type: 'Клавиатура', item_model: 'OKLICK') || create(:new_item, warehouse_type: :without_invent_num, item_type: 'Клавиатура', item_model: 'OKLICK', count: 20, count_reserved: 2)
            item2 = Item.find_by(item_type: 'Мышь', item_model: 'Logitech') || create(:new_item, warehouse_type: :without_invent_num, item_type: 'Мышь', item_model: 'Logitech', count: 20, count_reserved: 2)

            order.operations << build(:order_operation, item: item1, item_type: 'Клавиатура', item_model: 'OKLICK', shift: -2)
            order.operations << build(:order_operation, item: item2, item_type: 'Мышь', item_model: 'Logitech', shift: -2)
          end
        elsif order.operation.to_s == 'write_off'
          if order.operations.empty? && !ev.without_operations
            item = create(:item, :with_property_values, type_name: :monitor)
            w_item = create(:used_item, inv_item: item)

            order.operations << build(:order_operation, item: w_item, inv_item_ids: [item.item_id], shift: -1)
          end
        end
      end
    end
  end
end
