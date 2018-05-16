class UsersController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        @index = Users::Index.new(params)

        if @index.run
          render json: @index.data
        else
          render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
        end
      end
    end
  end

  def new
    @new_user = Users::NewUser.new

    if @new_user.run
      render json: @new_user.data
    else
      render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
    end
  end

  def create
    @create = Users::Create.new(user_params)

    if @create.run
      render json: { full_message: I18n.t('controllers.user.created') }
    else
      render json: @create.error, status: 422
    end
  end

  def edit
    @edit = Users::Edit.new(params[:id])

    if @edit.run
      render json: @edit.data
    else
      render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
    end
  end

  def update
    @update = Users::Update.new(params[:id], user_params)

    if @update.run
      render json: { full_message: I18n.t('controllers.user.updated') }
    else
      render json: @update.error, status: 422
    end
  end

  def destroy
    @destroy = Users::Destroy.new(params[:id])

    if @destroy.run
      render json: { full_message: I18n.t('controllers.user.destroyed') }
    else
      render json: { full_message: @destroy.error }, status: 422
    end
  end

  protected

  def user_params
    params.require(:user).permit(:id, :tn, :role_id)
  end
end