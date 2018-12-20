module Warehouse
  module Orders
    module WriteOff
      class AbstractState
        include Broadcast

        def initialize(order)
          @order = order
        end

        def new_item_status; end

        def processing_operations(user); end

        def edit_warehouse_item_for(operation); end

        def broadcast_orders; end
      end
    end
  end
end
