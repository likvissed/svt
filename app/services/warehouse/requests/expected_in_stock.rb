module Warehouse
  module Requests
    class ExpectedInStock < Warehouse::ApplicationService
      def initialize(current_user, request_id, flag)
        @current_user = current_user
        @request_id = request_id
        @flag = flag

        super
      end

      def run
        load_request
        update_status

        broadcast_requests

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @request, :expected_is_stock?
      end

      def update_status
        case @flag
        when true
          raise 'Статус заявки не изменён' unless @request.update(status: :expected_in_stock)

          Orbita.add_event(@request_id, @current_user.id_tn, 'workflow', { message: 'Изменил статус на "Ожидание наличия техники"' })
        when false
          raise 'Статус заявки не изменён' unless @request.update(status: :create_order)

          Orbita.add_event(@request_id, @current_user.id_tn, 'workflow', { message: 'Изменил статус на "Требуется создать ордер"' })
        end
      end
    end
  end
end
