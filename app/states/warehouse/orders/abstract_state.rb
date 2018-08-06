module Warehouse
  module Orders
    class AbstractState
      include Broadcast

      def initialize(order)
        @order = order
      end

      def init_operations(user); end

      def update_inv_items(order); end

      def init_warehouse_item(operation); end

      def edit_warehouse_item(w_item); end

      def update_warehouse_item(w_item, inv_item); end

      def broadcast_orders; end
    end
  end
end
