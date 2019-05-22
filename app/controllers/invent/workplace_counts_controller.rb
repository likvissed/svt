module Invent
  class WorkplaceCountsController < ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          workplace_count = {}
          workplace_count[:array] = WorkplaceCount.select('invent_workplace_count.*')
                                      .includes(:users)
                                      .left_outer_joins(:workplaces)
                                      .order('CAST(division AS UNSIGNED INTEGER)')
                                      .limit(params[:length])
                                      .offset(params[:start])
                                      .left_outer_joins(:workplaces)
                                      .group(:workplace_count_id)
                                      .select('SUM(CASE WHEN invent_workplace.status = 3 THEN 1 ELSE 0 END) as freezed ')
                                      .select('SUM(CASE WHEN invent_workplace.status = 0 THEN 1 ELSE 0 END) as confirmed ')
                                      .select('SUM(CASE WHEN invent_workplace.status = 1 THEN 1 ELSE 0 END) as pending_verification ')
                                      .as_json(
                                        include: :users
                                      ).each do |division|

                                        # Фио ответственного
                                        division['user_fullname'] = division['users'].present? ? division['users'].map { |us| us['fullname'] } : 'Ответственный не найден'

                                        # Телефон
                                        division['user_phone'] = division['users'].present? ? division['users'].map { |ph| ph['phone'] } : 'Телефон не найден'

                                        # Время доступа
                                        division['user_time'] = division['time_start'].strftime('%d.%m.%Y') + ' - ' + division['time_end'].strftime('%d.%m.%Y')

                                        # Проверка статуса (Доступ открыт или закрыт)
                                        division['status_name'] = division['time_start'] <= Time.zone.now && Time.zone.now <= division['time_end'] ? 'Доступ открыт' : 'Доступ закрыт'

                                        division.delete('users')
                                        division.delete('time_start')
                                        division.delete('time_end')
                                      end
          workplace_count[:recordsTotal] = WorkplaceCount.count
          workplace_count[:recordsFiltered] = WorkplaceCount.count

        # Rails.logger.info "wpC #{query}".yellow

          render json: workplace_count
        end
      end
    end
  end
end