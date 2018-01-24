module Warehouse
  module Orders
    # Изменение приходного ордера
    class Update < BaseService
      def initialize(order_id, order_params)
        @error = {}
        @order_id = order_id
        @order_params = order_params
      end

      def run
        @order = Order.includes(:item_to_orders).find(@order_id)
        processing_nested_attributes if @order_params['operations_attributes']&.any?
        wrap_order_with_transaction

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_nested_attributes

      end

      def wrap_order_with_transaction
        @order.transaction do
          begin
            find_or_create_warehouse_items
          rescue ActiveRecord::RecordNotSaved
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def find_or_create_warehouse_items
      end
    end
  end
end
