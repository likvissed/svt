module Warehouse
  module Requests
    class SaveRecommendation < Warehouse::ApplicationService
      def initialize(current_user, request_id, request_params)
        @current_user = current_user
        @request_id = request_id
        @request_params = request_params

        super
      end

      def run
        load_request
        check_recommendation unless @request_params['recommendation_json'].nil?
        save_request

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

        authorize @request, :save_recommendation?
      end

      def check_recommendation
        @request_params['recommendation_json'].each do |rec|
          next if rec['name'] != 'Выберите рекомендацию'

          error[:full_message] = 'Необходимо заполнить все поля рекомендаций'
          raise 'Данные не обновлены'
        end
      end

      def save_request
        @form = Requests::SaveRecommendationForm.new(Request.find(@request_id))

        if @form.validate(@request_params)
          @form.save

          Orbita.add_event(@request_id, @current_user.id_tn, 'workflow', { message: 'Создан список рекомендаций' })
        else
          error[:full_message] = @form.errors.full_messages.join('. ')

          raise 'Данные не обновлены'
        end
      end
    end
  end
end
