
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

    # Этап № 1 - Назначить исполнителя и поменять статус
    def send_for_analysis
      analysis = Requests::SendForAnalysis.new(current_user, params[:id], request_params)

      if analysis.run
        render json: { full_message: 'Статус заявки успешно изменен' }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    # Сменить исполнителя для заявки
    def assign_new_executor
      executor = Requests::AssignNewExecutor.new(current_user, params[:id], params[:executor])

      if executor.run
        render json: { full_message: 'Исполнитель успешно переназначен' }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    # Этап № 2 Сохранить сформированный список рекомендаций и отправить на проверку администратору
    def save_recommendation
      recommendation = Requests::SaveRecommendation.new(current_user, params[:id], request_params)

      if recommendation.run
        render json: { full_message: 'Список рекомендаций сохранён' }, status: 200
      else
        render json: recommendation.error, status: 422
      end
    end

    # Этап № 3 Отправить список рекомендаций в ССД руководителю
    def send_to_owner
      request = Requests::SendToOwner.new(current_user, params[:id], params[:owner], request_params)

      if request.run
        render json: { full_message: "Заявка №#{params[:id]} отправлена на подпись в ССД" }, status: 200
      else
        render json: request.error, status: 422
      end
    end

    # Изменить статус как "Ожидание наличия техники" или обратно "Требуется создать ордер"
    def expected_is_stock
      expect = Requests::ExpectedInStock.new(current_user, params[:id], params[:flag])

      if expect.run
        render json: { full_message: 'Статус изменён' }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    # Этап №6 Администратор подтверждает/отклоняет заявку и ордер
    def confirm_request_and_order
      request = Requests::SendForConfirm.new(current_user, params[:id], params[:order_id])

      if request.run
        render json: { full_message: "Заявка №#{params[:id]} и ордер №#{params[:order_id]} утверждены" }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    # Этап №8 Исполнитель подтверждает готовность к выдаче техники пользователю
    def ready
      request = Requests::Ready.new(current_user, params[:id])

      if request.run
        render json: { full_message: 'Уведомление о готовности к выдаче техники пользователю отправлено' }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    # Обновить комментарий
    def update
      request = Requests::Update.new(current_user, params[:id], request_params)

      if request.run
        render json: { full_message: 'Комментарий обновлен' }, status: 200
      else
        render json: request.error, status: 422
      end
    end

    # Закрыть заявку и удалить ордер если имеется
    def close
      close = Requests::Close.new(current_user, params[:id])

      if close.run
        render json: { full_message: "Заявка №#{params[:id]} закрыта" }, status: 200
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    protected

    def request_params
      params.require(:request).permit(
        :request_id,
        :category,
        :executor_fio,
        :executor_tn,
        :comment,
        :status,
        recommendation_json: [
          :name
        ]
      )
    end
  end
end
