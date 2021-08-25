module Warehouse
  module Orders
    class Confirm < BaseService
      def initialize(current_user, order_id, comment = nil)
        @current_user = current_user
        @order_id = order_id
        @comment = comment

        super
      end

      def run
        find_order
        save_order(@order)

        if @order.in?
          broadcast_in_orders
        elsif @order.out?
          broadcast_out_orders
        elsif @order.write_off?
          broadcast_write_off_orders
        end

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.find(@order_id)
        authorize @order, :confirm?

        @order.set_validator(current_user)
        @order.comment = @comment
      end
    end
  end
end
