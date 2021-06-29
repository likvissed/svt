class UserIssesController < ApplicationController
  skip_before_action :authenticate_user!, only: :items

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

  def items
    @workplaces = Invent::Workplace.where(id_tn: params[:user_iss_id]).includes(items: %i[type model barcode_item])
    result = @workplaces
               .as_json(include: {
                 items: {
                   include: %i[type barcode_item],
                   except: %i[create_time modify_time],
                   methods: :short_item_model
                 }
               })
               .map { |wp| wp['items'] }.flatten

    render json: result
  end
end
