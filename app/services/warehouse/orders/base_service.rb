module Warehouse
  module Orders
    class BaseService < Warehouse::ApplicationService
      def broadcast_orders
        ActionCable.server.broadcast 'orders', nil
      end

      protected

      def warehouse_item_in(inv_item)
        begin
          item = Item.find_or_create_by!(invent_item_id: inv_item.item_id) do |w_item|
            w_item.inv_item = inv_item
            w_item.inv_type = inv_item.type
            w_item.inv_model = inv_item.model
            w_item.warehouse_type = :with_invent_num
            w_item.used = true

            w_item.was_created = true
          end
        rescue ActiveRecord::RecordNotUnique
          item = Item.find(io[:invent_item_id])
        end

        unless item.was_created
          item.update!(item_model: inv_item.get_item_model)
        end

        @order.operations.select { |op| op.inv_item_ids.first == inv_item.item_id }.each do |op|
          op.item = item

          if Invent::Type::TYPE_WITH_FILES.include?(op.item.inv_item.type.name)
            op.item_model = op.item.inv_item.get_item_model
          end
        end
      end

      def save_order(order)
        return if order.save

        process_order_errors(order)
        raise 'Ордер не сохранен'
      end

      def process_order_errors(order, with_operations = false)
        error[:object] = order.errors
        error[:full_message] = if with_operations
                                 order_errors = order.errors.full_messages
                                 operation_errors = order.operations.map { |op| op.errors.full_messages }
                                 [order_errors, operation_errors].flatten.join('. ')
                               else
                                 order.errors.full_messages.join('. ')
                               end
      end
    end
  end
end
