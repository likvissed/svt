module Warehouse
  module Orders
    module WriteOff
      class DoneState < AbstractState
        def new_item_status
          :written_off
        end

        def processing_operations(user)
          @order.operations.each do |op|
            op.set_stockman(user)
            op.status = :done
          end
        end

        def edit_warehouse_item_for(operation)
          operation.item.count = 0
          operation.item.count_reserved = 0
        end

        def broadcast_data
          broadcast_archive_orders

          super
        end
      end
    end
  end
end
