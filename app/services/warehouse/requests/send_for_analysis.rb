module Warehouse
  module Requests
    # Назначить исполнителя и поменять статус (Этап №2)
    class SendForAnalysis < Warehouse::ApplicationService
      def initialize(current_user, request_id, request_params)
        @current_user = current_user
        @request_id = request_id
        @request_params = request_params

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

        authorize @request, :send_for_analysis?
      end

      def update_status
        @form = Requests::SendForAnalysisForm.new(Request.find(@request_id))

        if @form.validate(@request_params)
          @form.save
          Orbita.add_event(@request_id, @current_user.id_tn, 'add_workers', { tns: [@form.executor_tn] })
        end
      end
    end
  end
end
