module Warehouse
  FactoryBot.define do
    factory :order_operation, class: Operation do
      item nil
      stockman_id_tn 20868
      operationable_id nil
      operationable_type 'Warehouse::Order'
      item_type { Invent::Item.find_by(item_id: invent_item_id).try(:type).try(:short_description) || 'Test type' }
      item_model { Invent::Item.find_by(item_id: invent_item_id).try(:item_model) || 'Test model' }
      shift 1
      status 'processing'
      invent_item_id nil

      after(:build) do |op|
        op.stockman_fio = op.stockman_id_tn ? UserIss.find(op.stockman_id_tn).fio : ''
      end
    end
  end
end
