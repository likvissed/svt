module Warehouse
  module Orders
    class ConfirmOut < BaseService
      def initialize(current_user, order_id)
        @current_user = current_user
        @order_id = order_id

        super
      end

      def run
        find_order
        raise 'Неверные данные' if @order.operation != 'out'

        save_order(@order)
        broadcast_out_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.find(@order_id)
        authorize @order, :confirm_out?
        @order.set_validator(current_user)
      end
    end
  end
end
