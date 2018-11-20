module Warehouse
  module Orders
    class DoneState < AbstractState
      def init_operations(user)
        @order.operations.each do |op|
          op.set_stockman(user)
          op.status = :done
        end
      end

      def update_inv_items(order)
        order.operations.each { |op| op.inv_items.each { |inv_item| inv_item.to_stock! } }
      end

      def init_warehouse_item(operation)
        operation.build_item(
          warehouse_type: :without_invent_num,
          item_type: operation.item_type,
          item_model: operation.item_model,
          used: true,
          count: 1,
          count_reserved: 0
        )
      end

      def edit_warehouse_item(w_item)
        w_item.count = 1
        w_item.count_reserved = 0
      end

      def update_warehouse_item(w_item, inv_item)
        w_item.update!(item_model: inv_item.get_item_model, count: 1, count_reserved: 0, allow_update_model_or_type: true)
      end

      def broadcast_orders
        broadcast_archive_orders
      end
    end
  end
end
