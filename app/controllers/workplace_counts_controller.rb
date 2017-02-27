class WorkplaceCountsController < ApplicationController
  before_action :find_by_id, only: [:update, :destroy]

  def index
    respond_to do |format|
      format.html
      format.json do
        # @workplace_counts = WorkplaceCount
        #                       .joins('LEFT OUTER JOIN invent_workplace r ON r.workplace_id = invent_workplace_count
# .workplace_count_id and r.status = 0')
#                               .joins('LEFT OUTER JOIN invent_workplace w ON w.workplace_count_id =
# invent_workplace_count.workplace_count_id and w.status = 1')
#                               .left_outer_joins(:user_iss)
#                               .select('invent_workplace_count.*, user_iss.fio as responsible, COUNT(r
# .workplace_id) as ready, COUNT(w.workplace_id) as waiting')
#                               .group('invent_workplace_count.workplace_count_id')

        @workplace_counts = WorkplaceCount
                              .joins('LEFT OUTER JOIN invent_workplace r ON r.workplace_id = invent_workplace_count
.workplace_count_id and r.status = 0')
                              .joins('LEFT OUTER JOIN invent_workplace w ON w.workplace_count_id =
invent_workplace_count.workplace_count_id and w.status = 1')
                              .includes(:workplace_responsibles, :user_isses)
                              .select('invent_workplace_count.*, COUNT(r.workplace_id) as ready, COUNT(w
.workplace_id) as waiting')
                              .group('invent_workplace_count.workplace_count_id')


        # SELECT invent_workplace_count.*, fio_initials as responsible, COUNT(r.workplace_id) as ready, COUNT(w.workplace_id) as waiting
        # FROM `invent_workplace_count`
        # LEFT OUTER JOIN invent_workplace r ON
        #   r.`workplace_count_id` = invent_workplace_count.workplace_count_id AND
        #   r.`status` = 0
        # LEFT OUTER JOIN invent_workplace w ON
        #   w.`workplace_count_id` = invent_workplace_count.workplace_count_id AND
        #   w.`status` = 1
        # LEFT OUTER JOIN `user_iss` ON
        #   `user_iss`.`id_tn` = `invent_workplace_count`.`id_tn`
        # GROUP BY invent_workplace_count.workplace_count_id;

        @workplace_counts = @workplace_counts
                              .as_json(
                                {
                                  include:
                                    {
                                      workplace_responsibles:
                                        {
                                          only: [:id_tn, :phone],
                                          include: { user_iss: { only: [:tn, :fio] } }
                                        }
                                    }
                                }
                              )
                              .each do |c|
                                c['date-range']   = "#{c['time_start']} - #{c['time_end']}"
                                c['responsibles'] = []
                                c['phone']        = []

                                c['workplace_responsibles'].each do |resp|
                                  c['responsibles'] << resp['user_iss']['fio'] unless resp['user_iss'].nil?
                                  c['phone']        << resp['phone'] unless resp['phone'].empty?
                                end

                                c['responsibles'] = c['responsibles'].join(', ')
                                c['phone'] = c['phone'].join(', ')
                              end

        render json: @workplace_counts
      end
    end
  end

  def create
    @workplace_count = WorkplaceCount.new(workplace_count_params)

    if @workplace_count.save
      render json: { full_message: "Отдел #{@workplace_count.division} добавлен." }, status: :created
    else
      render json: { object: @workplace_count.errors, full_message: "Ошибка. #{ @workplace_count.errors
        .full_messages.join(", ") }" }, status: :unprocessable_entity
    end
  end

  def show
    @workplace_count = WorkplaceCount
                        .includes(:workplace_responsibles, :user_isses)
                        .select('invent_workplace_count.*')
                        .where(workplace_count_id: params[:workplace_count_id])
                        .first

    @workplace_count = @workplace_count
                         .as_json(
                           {
                             include:
                               {
                                workplace_responsibles:
                                  {
                                    include: { user_iss: { only: [:id_tn, :tn] } }
                                  },
                               }
                           }
                         )

    @workplace_count['workplace_responsibles'] = @workplace_count['workplace_responsibles'].each do |resp|
      resp['id'] = resp['workplace_responsible_id']

      resp['tn'] = resp['user_iss']['tn']

      resp.delete('user_iss')
      resp.delete('id_tn')
    end

    @workplace_count['workplace_responsibles_attributes'] = @workplace_count['workplace_responsibles']
    @workplace_count.delete('workplace_responsibles')
    # hash = @workplace_count.as_json.delete_if { |key, value| ['id_tn', 'tn', 'status'].include? key }
    # hash['tn'] = hash['user_tn']
    # hash.delete('user_tn')

    render json: @workplace_count
  end

  def update
    if @workplace_count.update_attributes(workplace_count_params)
      render json: { full_message: 'Данные обновлены.' }, status: :ok
    else
      render json: { object: @workplace_count.errors, full_message: "Ошибка. #{ @workplace_count.errors
        .full_messages.join(",")}" }, status: :unprocessable_entity
    end
  end

  def destroy
    if @workplace_count.destroy
      render json: { full_message: 'Отдел удален.' }, status: :ok
    else
      render json: { full_message: "Ошибка. #{ @workplace_count.errors.full_messages.join(", ") }" }, status:
        :unprocessable_entity
    end
  end

  # Если у пользователя есть доступ, в ответ присылается html-код кнопки "Добавить" для создания новой записи
  # Запрос отсылается из JS файла при инициализации таблицы "Сервисы"
  def link_to_new_record
    link = create_link_to_new_record :modal, WorkplaceCount, "ng-click='wpCount.openWpCountEditModal()'"

    render json: link
  end

  private

  def find_by_id
    @workplace_count = WorkplaceCount.find(params[:workplace_count_id])
  end

  def workplace_count_params
    params.require(:workplace_count).permit(
      :workplace_count_id,
      :count_wp,
      :division,
      :time_start,
      :time_end,
      workplace_responsibles_attributes: [
        :id,
        # :workplace_responsible_id,
        :workplace_count_id,
        :id_tn,
        :tn,
        :phone,
        :_destroy
      ]
    )
  end
end
