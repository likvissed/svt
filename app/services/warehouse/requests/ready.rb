module Warehouse
  module Requests
    class Ready < Warehouse::ApplicationService
      def initialize(current_user, request_id)
        @current_user = current_user
        @request_id = request_id

        super
      end

      def run
        load_request
        update_status
        send_notice_to_user

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @request, :ready?
      end

      def update_status
        @request.update(status: 'ready')
      end

      def send_notice_to_user
        # Обязательно присутствие пользователя для его подписи при выдаче
        Orbita.add_event(@request_id, @current_user.id_tn, 'to_user_message', { message: 'Техника готова к выдаче. Необходима будет личная подпись' })
      end
    end
  end
end
