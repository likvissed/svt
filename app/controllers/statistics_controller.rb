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
      format.xlsx do
        if params[:data].present?
          Axlsx::Package.new do |p|
            p.workbook.add_worksheet(name: "sheet name" ) do |sheet|    
              sheet.add_row ['Наименование', 'Общее количество', 'На замену']
              JSON.parse(params[:data]).each do |dt|
                sheet.add_row [dt['description'], dt['total_count'], dt['to_replace_count']]
              end
            end

            send_data p.to_stream.read, filename: "Статистика по батареям ИБП КВРМ-#{Time.zone.today}.xlsx", disposition: :attachment
          end
        end
      end
    end
  end
end
