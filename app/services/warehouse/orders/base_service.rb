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

      def create_array_location_for_items(operations)
        array_locations = []

        operations.each do |op|
          if op['inv_item_ids'].present? && op['location'].present?
            value = {}
            value[:id_inv_item] = op['inv_item_ids'].first
            value[:location] = op['location'].as_json

            array_locations.push(value)
          end

          op.delete(:location)
        end

        array_locations
      end

      def assiged_location_for_w_items(array_locations)
        array_locations.each do |item_for_location|
          w_item = Item.find_by(invent_item_id: item_for_location[:id_inv_item])

          item_params = w_item.as_json
          item_params['location_attributes'] = item_for_location[:location]

          # Присвоить расположение для техники
          Items::Update.new(@current_user, w_item.id, item_params).run
        end
      end

      def save_order(order)
        return if order.save

        process_order_errors(order)
        raise 'Ордер не сохранен'
      end

      def process_order_errors(order, with_operations = false)
        error[:object] = if order.operation == 'out'
                           error_operations_for_index(order)
                         else
                           order.errors
                         end

        error[:full_message] = if with_operations
                                 order_errors = order.errors.full_messages
                                 operation_errors = order.operations.map { |op| op.errors.full_messages }
                                 [order_errors, operation_errors].flatten.join('. ')
                               else
                                 order.errors.full_messages.join('. ')
                               end
      end

      def error_operations_for_index(order)
        new_operations = order.operations.select { |op| op if op.status_changed? }
        new_hash = {}

        new_operations.each_with_index do |operation, ind|
          operation.inv_items.each_with_index do |item, jnd|
            item.errors.messages.each do |ms|
              new_hash["operations[#{ind}].inv_items[#{jnd}].#{ms.first}"] = ms.last

              new_hash.merge!(new_hash)
            end
          end
        end

        new_hash
      end
    end
  end
end
