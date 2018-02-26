module Warehouse
  FactoryBot.define do
    factory :order, class: Order do
      inv_workplace nil
      creator_id_tn ***REMOVED***
      validator_id_tn 5336
      operation :in
      status 'processing'
      consumer_dept { inv_workplace.try(:workplace_count).try(:division) || ***REMOVED*** }
      comment ''

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

        if order.operations.empty? && !ev.without_operations
          if order.inv_workplace
            inv_item = order.inv_workplace.items.first
            item = build(:used_item, inv_item: inv_item)
            order.operations << build(:order_operation, item: item, inv_items: [inv_item])
            # order.item_to_orders << build(:item_to_order, inv_item: item.inv_item)
          else
            # create(:item, :with_property_values, type_name: :monitor)
            order.operations << build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK')
            order.operations << build(:order_operation, item_type: 'Мышь', item_model: 'Logitech')
          end
        end
      end
    end
  end
end
