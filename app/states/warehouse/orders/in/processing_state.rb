module Warehouse
  module Orders
    module In
      class ProcessingState < AbstractState
        def update_inv_items(order, _access_token)
          order.operations.each { |op| op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_bring) } }
        end

        def update_warehouse_item(w_item, inv_item)
          # атрибут allow_update_model_or_type добавлен, тк в DoneState(сразу исполнение ордера) он передан
          w_item.update!(item_model: inv_item.full_item_model, allow_update_model_or_type: true)
        end

        def broadcast_data
          broadcast_in_orders

          super
        end
      end
    end
  end
end
