module Warehouse
  FactoryBot.define do
    factory :order, class: Order do
      workplace { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      creator_id_tn ***REMOVED***
      validator_id_tn 5336
      operation :in
      status :processing
      consumer_dept ***REMOVED***
      comment ''

      transient do
        without_operations false
      end

      trait :without_operations do
        without_operations true
      end

      after(:build) do |order, ev|
        order.creator_fio = order.creator_id_tn ? UserIss.find(order.creator_id_tn).fio : ''
        order.validator_fio = order.validator_id_tn ? UserIss.find(order.validator_id_tn).fio : ''

        if order.operations.empty? && !ev.without_operations
          monitor = create(:item, :with_property_values, type_name: :monitor)
          item = build(:used_item, inv_item: monitor)
          order.operations << build(:order_operation, item: item)
          # order.item_to_orders << build(:item_to_order, inv_item: item.inv_item)
        end
      end
    end
  end
end
