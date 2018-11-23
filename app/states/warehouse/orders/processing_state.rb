module Warehouse
  module Orders
    class ProcessingState < AbstractState
      def update_inv_items(order)
        order.operations.each { |op| op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_bring) } }
      end

      def update_warehouse_item(w_item, inv_item)
        w_item.update!(item_model: inv_item.full_item_model)
      end

      def broadcast_orders
        broadcast_in_orders
      end
    end
  end
end
