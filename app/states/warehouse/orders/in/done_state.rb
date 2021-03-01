module Warehouse
  module Orders
    module In
      class DoneState < AbstractState
        def processing_operations(user)
          @order.operations.each do |op|
            op.set_stockman(user)
            op.status = :done
          end
        end

        def update_inv_items(order, access_token)
          order.operations.each do |op|
            op.inv_items.each do |inv_item|
              inv_item.to_stock!
              UnregistrationWorker.perform_async(inv_item.invent_num, access_token)
            end
          end
        end

        def init_warehouse_item(operation)
          if operation.item.present? && Invent::Property::LIST_TYPE_FOR_BARCODES.include?(operation.item.item_type.to_s.downcase)
            operation.item.count = 1
            operation.item.status = :used
            operation.item.invent_property_value.mark_for_destruction
          else
            operation.build_item(
              warehouse_type: :without_invent_num,
              item_type: operation.item_type,
              item_model: operation.item_model,
              status: :used,
              count: 1,
              count_reserved: 0
            )
          end
        end

        def edit_warehouse_item(w_item)
          w_item.count = 1
          w_item.count_reserved = 0
        end

        def update_warehouse_item(w_item, inv_item)
          w_item.update!(item_model: inv_item.full_item_model, count: 1, count_reserved: 0, allow_update_model_or_type: true)
        end

        def broadcast_data
          broadcast_archive_orders

          super
        end
      end
    end
  end
end
