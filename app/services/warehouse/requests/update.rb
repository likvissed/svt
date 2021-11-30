module Warehouse
  module Requests
    class Update < Warehouse::ApplicationService
      def initialize(current_user, request_id, request_params)
        @current_user = current_user
        @request_id = request_id
        @request_params = request_params

        super
      end

      def run
        load_request
        update_comment

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @request, :update?
      end

      def update_comment
        @form = Requests::UpdateCommentForm.new(Request.find(@request_id))

        if @form.validate(@request_params)
          @form.save
        else
          error[:full_message] = @form.errors[:base].join('. ')

          raise 'Данные не обновлены'
        end
      end
    end
  end
end
