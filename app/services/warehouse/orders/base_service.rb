module Warehouse
  module Orders
    class BaseService < ApplicationService
      def broadcast_orders
        ActionCable.server.broadcast 'orders', nil
      end

      protected

      def warehouse_item(io)
        begin
          item = Item.find_or_create_by!(invent_item_id: io[:invent_item_id]) do |w_item|
            w_item.inv_item = io.inv_item
            w_item.type = io.inv_item.type
            w_item.model = io.inv_item.model
            w_item.warehouse_type = :returnable
            w_item.used = true
          end
        rescue ActiveRecord::RecordNotUnique
          item = Item.find(io[:invent_item_id])
        end

        @order.operations.select { |op| op.invent_item_id == io.invent_item_id }.each do |op|
          op.item = item

          if Invent::Type::TYPE_WITH_FILES.include?(op.item.inv_item.type.name)
            op.item_model = op.item.inv_item.get_item_model
          end
        end
      end

      def save_order(order)
        return if order.save

        error[:object] = order.errors
        error[:full_message] = order.errors.full_messages.join('. ')
        raise 'Ордер не сохранен'
      end
    end
  end
end
