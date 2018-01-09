module Warehouse
  module Orders
    # Изменение приходного ордера
    class Update < BaseService
      attr_reader :error

      def initialize(order_id, order_params)
        @error = {}
        @order_id = order_id
        @order_params = order_params
      end

      def run
        @order = Order.includes(:item_to_orders).find(@order_id)
        wrap_order_with_transaction

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

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
