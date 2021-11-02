
module Warehouse
  class RequestsController < Warehouse::ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Requests::Index.new(params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def send_for_analysis
      @form = Requests::SendForAnalysisForm.new(Request.find(params['id']))

      if @form.validate(request_params)
        @form.save
        # Rails.logger.info "success: #{@form.inspect}".green
        render json: { full_message: 'Статус заявки успешно изменен' }, status: 200
      else
        # Rails.logger.info "error: #{@form.inspect}".red
        # .model_name.i18n_key
        render json: { full_message: @form.errors.full_messages.join('. ') }, status: 422
      end
    end

    protected

    def request_params
      params.require(:request).permit(
        :request_id,
        :category,
        :number_***REMOVED***,
        :order_id,
        :executor_fio,
        :comment,
        :status
      )
    end
  end
end
