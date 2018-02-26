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
        @order = Order.includes(:inv_item_to_operations).find(@order_id)
        return false unless wrap_order_with_transactions
        broadcast_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def wrap_order_with_transactions
        Item.transaction do
          begin
            assign_order_params

            find_or_create_warehouse_items
            Invent::Item.transaction(requires_new: true) do
              update_inv_items
              save_order(@order)
            end

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

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
        @order.operations.each do |op|
          next if op.id || op._destroy

          op.inv_items.each { |inv_item| warehouse_item_in(inv_item) }
        end
      end

      def update_inv_items
        return unless @order.inv_workplace

        @order.operations.each do |op|
          if op.new_record?
            op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_bring) }
          elsif op._destroy
            op.inv_items.each { |inv_item| inv_item.update!(status: nil) }
          end
        end
      end
    end
  end
end
