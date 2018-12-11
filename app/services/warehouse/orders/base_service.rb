module Warehouse
  module Orders
    class BaseService < Warehouse::ApplicationService
      protected

      def order_out?
        @order_params['operation'] == 'out' && @order_params['operations_attributes']&.all? { |op| op['shift'].to_i.negative? }
      end

      def order_in?
        @order_params['operation'] == 'in' && @order_params['operations_attributes']&.all? { |op| op['shift'].to_i.positive? }
      end

      def order_write_off?
        @order_params['operation'] == 'write_off' && @order_params['operations_attributes']&.all? { |op| op['shift'].to_i.negative? }
      end

      def warehouse_item_in(inv_item)
        begin
          item = Item.find_or_create_by!(invent_item_id: inv_item.item_id) do |w_item|
            w_item.inv_item = inv_item
            w_item.inv_type = inv_item.type
            w_item.inv_model = inv_item.model
            w_item.warehouse_type = :with_invent_num
            w_item.status = :used

            @order_state.edit_warehouse_item(w_item)

            w_item.was_created = true
          end
        rescue ActiveRecord::RecordNotUnique
          item = Item.find(io[:invent_item_id])
        end

        @order_state.update_warehouse_item(item, inv_item) unless item.was_created

        @order.operations.select { |op| op.inv_item_ids.first == inv_item.item_id }.each do |op|
          op.item = item
          op.item_model = op.item.inv_item.full_item_model if Invent::Type::TYPE_WITH_FILES.include?(op.item.inv_item.type.name)
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
