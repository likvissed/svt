module Warehouse
  FactoryBot.define do
    factory :order_operation, class: Operation do
      item { nil }
      stockman_id_tn { nil }
      operationable_id { nil }
      operationable_type { 'Warehouse::Order' }
      item_type { item.try(:item_type) || inv_items.try(:first).try(:type).try(:short_description) || 'Test type' }
      item_model { item.try(:item_model) || inv_items.try(:first).try(:full_item_model) || 'Test model' }
      shift { 1 }
      status { :processing }

      after(:build) do |op|
        op.stockman_fio = op.stockman_id_tn ? UserIss.find(op.stockman_id_tn).fio : nil
      end
    end

    factory :supply_operation, class: Operation do
      operationable_type { 'Warehouse::Supply' }
      shift { 1 }
      status { :processing }
      item_type { item.try(:item_type) || 'Test type' }
      item_model { item.try(:item_model) || 'Test model' }

      transient do
        skip_calculate_invent_nums { false }
      end

      after(:build) do |op|
        op.stockman_fio = op.stockman_id_tn ? UserIss.find(op.stockman_id_tn).fio : nil
      end
      before(:create) do |op, ev|
        op.calculate_item_invent_num_end if op.item && op.item.warehouse_type == 'with_invent_num' && !ev.skip_calculate_invent_nums
      end
    end
  end
end
