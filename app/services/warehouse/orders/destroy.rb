module Warehouse
  module Orders
    # Удалить ордер
    class Destroy < BaseService
      def initialize(order_id)
        @order_id = order_id
      end

      def run
        destroy_order
        broadcast_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def destroy_order
        @data = Order.find(@order_id)
        return if @data.destroy

        @data = @data.errors.full_messages.join('. ')
        raise 'Ордер не удален'
      end
    end
  end
end
