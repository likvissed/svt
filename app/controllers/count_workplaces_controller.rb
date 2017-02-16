class CountWorkplacesController < ApplicationController
  before_action :find_by_id, only: [:update, :destroy]

  def index
    respond_to do |format|
      format.html
      format.json do
        @count_workplaces = CountWorkplace
                              .joins('LEFT OUTER JOIN invent_workplace r ON r.workplace_id = invent_count_workplace
.count_workplace_id and r.status = 1')
                              .joins('LEFT OUTER JOIN invent_workplace w ON w.count_workplace_id =
invent_count_workplace.count_workplace_id and w.status = 2')
                              .left_outer_joins(:user_iss)
                              .select('invent_count_workplace.*, user_iss.fio_initials as responsible, COUNT(r
.workplace_id) as ready, COUNT(w.workplace_id) as waiting')
                              .group('invent_count_workplace.count_workplace_id')

        # SELECT invent_count_workplace.*, fio_initials as responsible, COUNT(r.workplace_id) as ready, COUNT(w.workplace_id) as waiting
        # FROM `invent_count_workplace`
        # LEFT OUTER JOIN invent_workplace r ON
        #   r.`count_workplace_id` = invent_count_workplace.count_workplace_id AND
        #   r.`status` = 1
        # LEFT OUTER JOIN invent_workplace w ON
        #   w.`count_workplace_id` = invent_count_workplace.count_workplace_id AND
        #   w.`status` = 2
        # LEFT OUTER JOIN `user_iss` ON
        #   `user_iss`.`id_tn` = `invent_count_workplace`.`id_tn`
        # GROUP BY invent_count_workplace.count_workplace_id;

        @count_workplaces = @count_workplaces.as_json.each do |c|
          c['date-range'] = "#{c['time_start']} - #{c['time_end']}"
          c['waiting']    = "#{c['waiting']}"
          c['ready']      = "#{c['ready']}/#{c['count_wp']}"
        end

        render json: @count_workplaces
      end
    end
  end

  def create
    @count_workplace = CountWorkplace.new(count_workplace_params)

    if @count_workplace.save
      render json: { full_message: "Отдел #{@count_workplace.division} добавлен." }, status: :created
    else
      render json: { object: @count_workplace.errors, full_message: "Ошибка. #{ @count_workplace.errors
        .full_messages.join(", ") }" }, status: :unprocessable_entity
    end
  end

  def show
    @count_workplace = CountWorkplace
                         .left_outer_joins(:user_iss)
                         .select('invent_count_workplace.*, user_iss.tn as user_tn')
                         .where(count_workplace_id: params[:count_workplace_id])
                         .first

    hash = @count_workplace.as_json.delete_if { |key, value| ['id_tn', 'tn', 'status'].include? key }
    hash['tn'] = hash['user_tn']
    hash.delete('user_tn')

    render json: hash
  end

  def update
    if @count_workplace.update_attributes(count_workplace_params)
      render json: { full_message: 'Данные обновлены.' }, status: :ok
    else
      render json: { object: @count_workplace.errors, full_message: "Ошибка. #{ @count_workplace.errors
        .full_messages.join(",")}" }, status: :unprocessable_entity
    end
  end

  def destroy
    if @count_workplace.destroy
      render json: { full_message: 'Отдел удален.' }, status: :ok
    else
      render json: { full_message: "Ошибка. #{ @count_workplace.errors.full_messages.join(", ") }" }, status:
        :unprocessable_entity
    end
  end

  # Если у пользователя есть доступ, в ответ присылается html-код кнопки "Добавить" для создания новой записи
  # Запрос отсылается из JS файла при инициализации таблицы "Сервисы"
  def link_to_new_record
    link = create_link_to_new_record :modal, CountWorkplace, "ng-click='countWp.openCountWpEditModal()'"

    render json: link
  end

  private

  def find_by_id
    @count_workplace = CountWorkplace.find(params[:count_workplace_id])
  end

  def count_workplace_params
    params.require(:count_workplace).permit(:id_tn, :tn, :phone, :division, :count_wp, :time_start, :time_end)
  end
end
