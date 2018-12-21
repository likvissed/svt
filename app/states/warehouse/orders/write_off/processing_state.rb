module Warehouse
  module Orders
    module WriteOff
      class ProcessingState < AbstractState
        def new_item_status
          :waiting_write_off
        end

        def edit_warehouse_item_for(operation)
          operation.calculate_item_count_reserved
        end

        def broadcast_data
          broadcast_write_off_orders

          super
        end
      end
    end
  end
end
