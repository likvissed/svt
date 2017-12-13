module Warehouse
  FactoryBot.define do
    factory :order, class: Order do
      workplace { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      creator { UserIss.where(dept: consumer_dept).first }
      consumer { UserIss.where(dept: consumer_dept).offset(1).first }
      validator { UserIss.where(fio: '***REMOVED***', dept: ***REMOVED***).first }
      operation :in
      status :processing
      creator_fio { creator.fio }
      consumer_fio { consumer.fio }
      validator_fio { validator.fio }
      consumer_dept ***REMOVED***
      comment ''

      transient do
        without_items false
      end

      trait :without_items do
        without_items true
      end

      after(:build) do |order, evaluator|
        unless evaluator.without_items
          order.item_to_orders_attributes = order.workplace.items.map do |item|
            { invent_item_id: item.item_id }
          end
        end
      end
    end
  end
end
