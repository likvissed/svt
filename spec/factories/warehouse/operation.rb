module Warehouse
  FactoryBot.define do
    factory :order_operation, class: Operation do
      item nil
      stockman_id_tn nil
      operationable_id nil
      operationable_type 'Warehouse::Order'
      item_type { item.try(:item_type) || inv_items.try(:first).try(:type).try(:short_description) || 'Test type' }
      item_model { item.try(:item_model) || inv_items.try(:first).try(:get_item_model) || 'Test model' }
      shift 1
      status :processing

      after(:build) do |op|
        op.stockman_fio = op.stockman_id_tn ? UserIss.find(op.stockman_id_tn).fio : nil
      end
    end
  end
end
