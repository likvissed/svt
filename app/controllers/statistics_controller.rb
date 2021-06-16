require 'csv'

class StatisticsController < ApplicationController
  def show
    @stat = Statistics.new

    if @stat.run(params[:type])
      render json: @stat.data
    else
      render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
    end
  end

  def export
    respond_to do |format|
      format.html
      format.csv do
        if params[:data].present?
          csv_data = CSV.generate(headers: true) do |csv|
            csv << ['Наименование', 'Общее количество', 'На замену']

            JSON.parse(params[:data]).each do |dt|
              csv << [dt['description'], dt['total_count'], dt['to_replace_count']]
            end
          end

          send_data csv_data, filename: "Статистика по батареям ИБП КВРМ-#{Time.zone.today}.csv", disposition: :attachment
        end
      end
    end
  end
end
