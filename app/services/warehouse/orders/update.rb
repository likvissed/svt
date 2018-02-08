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
        @new_operations = @order_params['operations_attributes'].reject { |op| op['id'] }
        @del_operations = @order_params['operations_attributes'].select { |op| op['_destroy'] }

        @order_params['item_to_orders_attributes'] = @order.item_to_orders.as_json.map do |io|
          io['id'] = io['warehouse_item_to_order_id']
          io['_destroy'] = @del_operations.any? { |op| op['invent_item_id'] == io['invent_item_id'] }

          io.delete('warehouse_item_to_order_id')
          io
        end
        @order_params['inv_item_ids'] = @new_operations.map { |op| op['invent_item_id'] }.compact.as_json
      end

      def wrap_order_with_transactions
        Item.transaction do
          begin
            assign_order_params

            find_or_create_warehouse_items
            Invent::Item.transaction(requires_new: true) do
              update_items
              save_order(@order)
            end

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
            raise ActiveRecord::Rollback
          rescue ActiveRecord::RecordNotDestroyed
            process_order_errors(@order, true)

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
        @order.inv_items.each do |item|
          next if @new_operations.none? { |op| op['invent_item_id'] == item.item_id }

          warehouse_item(item)
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
    end
  end
end
