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

        def update_inv_items(order)
          order.operations.each { |op| op.inv_items.each(&:to_stock!) }
        end

        def init_warehouse_item(operation)
          operation.build_item(
            warehouse_type: :without_invent_num,
            item_type: operation.item_type,
            item_model: operation.item_model,
            status: :used,
            count: 1,
            count_reserved: 0
          )
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
