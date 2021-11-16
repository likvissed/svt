module Warehouse
  module Requests
    class Close < Warehouse::ApplicationService
      def initialize(current_user_id_tn, request_id)
        @current_user_id_tn = current_user_id_tn
        @request_id = request_id

        super
      end

      def run
        load_request
        update_status
        delete_order if @request.order.present?
        send_into_***REMOVED***

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @data, :close?
      end

      def update_status
        @request.update(status: 'closed')
      end

      def delete_order
        @request.order.destroy
      end

      def send_into_***REMOVED***
        Orbita.add_event(@request.request_id, @current_user_id_tn, 'close')
      end
    end
  end
end
