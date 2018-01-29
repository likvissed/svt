module Warehouse
  module Orders
    # Изменение приходного ордера
    class Update < BaseService
      def initialize(current_user, order_id, order_params)
        @error = {}
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params.to_h
      end

      def run
        @order = Order.includes(:item_to_orders).find(@order_id)
        processing_nested_attributes if @order_params['operations_attributes']&.any?
        return false unless wrap_order_with_transactions
        broadcast_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_nested_attributes
        @new_operations = @order_params['operations_attributes'].select { |op| !op['id'] }
        @del_operations = @order_params['operations_attributes'].select { |op| op['_destroy'] }

        @order_params['item_to_orders_attributes'] = @order.item_to_orders.as_json.map do |io|
          io['id'] = io['warehouse_item_to_order_id']
          io['_destroy'] = @del_operations.any? { |op| op['invent_item_id'] == io['invent_item_id'] }

          io.delete('warehouse_item_to_order_id')
          io
        end
        @order_params['item_to_orders_attributes'].concat(
          @new_operations.reject { |op| !op['invent_item_id'] }.map { |op| { invent_item_id: op['invent_item_id'] } }.as_json
        )
      end

      def wrap_order_with_transactions
        assign_order_params

        Item.transaction do
          begin
            find_or_create_warehouse_items
            Invent::Item.transaction(requires_new: true) do
              update_items
              save_order
            end

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def assign_order_params
        @order.assign_attributes(@order_params)
        @order.set_creator(current_user)
      end

      def find_or_create_warehouse_items
        @order.item_to_orders.each do |io|
          if @new_operations.any? { |op| op['invent_item_id'] == io.invent_item_id }
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
        end
      end

      def update_items
        return unless @order.workplace

        @order.item_to_orders.each do |io|
          if @new_operations.any? { |op| op['invent_item_id'] == io.invent_item_id }
            io.inv_item.update!(status: :waiting_bring)
          elsif @del_operations.any? { |op| op['invent_item_id'] == io.invent_item_id }
            io.inv_item.update!(status: nil)
          end
        end
      end

      def save_order
        return if @order.save

        error[:object] = @order.errors
        error[:full_message] = @order.errors.full_messages.join('. ')
        raise 'Ордер не исполнен'
      end
    end
  end
end
