class StatisticsController < ApplicationController
  def show
    @stat = Statistics.new

    if @stat.run(params[:type])
      render json: @stat.data
    else
      render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
    end
  end
end
