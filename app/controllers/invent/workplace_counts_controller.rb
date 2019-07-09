module Invent
  class WorkplaceCountsController < ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          workplace_count = {}

          workplace_count_all = WorkplaceCount.all
          workplace_count[:recordsTotal] = workplace_count_all.count

          if params[:filters]
            filters_params = JSON.parse(params[:filters]).slice('division', 'responsible_fullname')
            workplace_count_all = workplace_count_all.filter(filters_params)
          end
          workplace_count[:recordsFiltered] = workplace_count_all.count

          workplace_count[:array] = workplace_count_all.select('invent_workplace_count.*')
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
                                      end
          render json: workplace_count
        end
      end
    end

    def edit
      edit_workplace_count = WorkplaceCount.find(params[:workplace_count_id]).as_json(include: :users)
      edit_workplace_count['user_ids'] = []
      edit_workplace_count['users_attributes'] = edit_workplace_count['users']
      edit_workplace_count.delete('users')

      render json: edit_workplace_count
    end

    def new
      new_workplace_count = WorkplaceCount.new.as_json

      new_workplace_count['user_ids'] = []
      new_workplace_count['users_attributes'] = []

      render json: new_workplace_count
    end

    def create
      create_workplace_count = WorkplaceCounts::Create.new(workplace_count_params)

      if create_workplace_count.run
        render json: { full_message: I18n.t('controllers.invent/workplace_count.created', dept: workplace_count_params[:division]) }
      else
        render json: create_workplace_count.error, status: 422
      end
    end

    def update
      update_workplace_count = WorkplaceCounts::Update.new(params[:workplace_count_id], workplace_count_params)

      if update_workplace_count.run
        render json: { full_message: I18n.t('controllers.invent/workplace_count.updated', dept: workplace_count_params[:division]) }
      else
        render json: update_workplace_count.error, status: 422
      end
    end

    def destroy
      delete_workplace_count = WorkplaceCount.find(params[:workplace_count_id])

      if delete_workplace_count.destroy
        render json: { full_message: I18n.t('controllers.invent/workplace_count.destroyed') }
      else
        error = {}
        error[:full_message] = delete_workplace_count.errors.full_messages.join('. ')
        render json: error, status: 422
      end
    end

    private

    def workplace_count_params
      params.require(:workplace_count).permit(
        :workplace_count_id,
        :division,
        :time_start,
        :time_end,
        user_ids: [],
        users_attributes: [
          :id,
          :id_tn,
          :tn,
          :fullname,
          :phone,
          :role_id
        ]
      )
    end
  end
end
