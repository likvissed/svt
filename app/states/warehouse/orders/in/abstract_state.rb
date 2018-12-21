module Warehouse
  module Orders
    module In
      class AbstractState
        include Broadcast

        def initialize(order)
          @order = order
        end

        def processing_operations(user); end

        def update_inv_items(order); end

        def init_warehouse_item(operation); end

        def edit_warehouse_item(w_item); end

        def update_warehouse_item(w_item, inv_item); end

        def broadcast_data
          broadcast_items
        end
      end
    end
  end
end
