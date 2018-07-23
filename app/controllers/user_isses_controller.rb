class UserIssesController < ApplicationController
  def index
    @index = UserIsses::Index.new(params[:search_key])

    if @index.run
      render json: @index.data
    else
      render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
    end
  end

  def users_from_division
    render json: UserIss.select(:id_tn, :fio).order(:fio).where(dept: params[:division])
  end
end