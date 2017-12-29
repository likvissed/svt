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

      after(:build) do |order|
        order.creator_fio = order.creator_id_tn ? UserIss.find(order.creator_id_tn).fio : ''
        order.validator_fio = order.validator_id_tn ? UserIss.find(order.validator_id_tn).fio : ''

        consumer = if order.consumer_id_tn
                     UserIss.find(order.consumer_id_tn)
                   else
                     UserIss.where(dept: order.consumer_dept).where('id_tn > 0').offset(1).first
                   end
        order.consumer_id_tn ||= consumer.id_tn
        order.consumer_fio = consumer.fio
      end
    end
  end
end
