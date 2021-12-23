module Warehouse
  module Requests
    # Подтвердить ордер и заявку (Этап №3)
    class SendForConfirm < Warehouse::ApplicationService
      def initialize(current_user, request_id, order_id)
        @current_user = current_user
        @request_id = request_id
        @order_id = order_id

        super
      end

      def run
        load_request
        confirm_order

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @request, :send_for_confirm?
      end

      def confirm_order
        return if Orders::Confirm.new(current_user, @order_id).run
      end
    end
  end
end
