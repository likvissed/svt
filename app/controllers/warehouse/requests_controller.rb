
module Warehouse
  class RequestsController < Warehouse::ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Requests::Index.new(current_user, params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def edit
      edit = Requests::Edit.new(current_user, params[:id])

      if edit.run
        render json: edit.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def send_for_analysis
      @form = Requests::SendForAnalysisForm.new(Request.find(params['id']))

      if @form.validate(request_params)
        @form.save
        Orbita.add_event(@form.model.number_***REMOVED***, current_user.id_tn, 'workflow', { message: "Назначен исполнитель: #{@form.executor_fio}" })
        # Rails.logger.info "success: #{@form.executor_fio}".red
        render json: { full_message: 'Статус заявки успешно изменен' }, status: 200
      else
        # Rails.logger.info "error: #{@form.inspect}".red
        # .model_name.i18n_key
        render json: { full_message: @form.errors.full_messages.join('. ') }, status: 422
      end
    end

    def close
      close = Requests::Close.new(current_user.id_tn, params[:id])

      if close.run
        render json: { full_message: "Заявка №#{params[:id]} закрыта" }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def confirm_request_and_order
      Rails.logger.info "params: #{params.inspect}".red

      request = Requests::SendForConfirm.new(current_user, params[:id], params[:order_id])

      if request.run
        render json: { full_message: "Заявка №#{params[:id]} и ордер №#{params[:order_id]} утверждены" }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    protected

    def request_params
      params.require(:request).permit(
        :request_id,
        :category,
        :number_***REMOVED***,
        :executor_fio,
        :executor_tn,
        :comment,
        :status
      )
    end
  end
end
