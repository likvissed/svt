module Warehouse
  module Requests
    # Подтвердить ордер и заявку
    class SendForConfirm < Warehouse::ApplicationService
      def initialize(current_user, request_id, order_id)
        @current_user = current_user
        @request_id = request_id
        @order_id = order_id

        super
      end

      def run
        load_request
        update_status_and_confirm_order


        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)
        # Rails.logger.info "current_user: #{@current_user.inspect}".green

        # authorize @request, :send_for_confirm?
      end

      def update_status_and_confirm_order
        @request.status = 'waiting_confirmation_for_user'
        Rails.logger.info "request: #{@request.inspect}".red

        if @request.save && Orders::Confirm.new(current_user, @order_id).run
          @request.order.set_validator(@current_user)
          send_into_***REMOVED***
        else
          false
        end
      end

      def send_into_***REMOVED***

      end
    end
  end
end
