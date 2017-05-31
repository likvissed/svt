module Inventory
  class WorkplaceCountsController < ApplicationController
    before_action :find_by_id, only: %i[update destroy]
    load_and_authorize_resource

    def index
      respond_to do |format|
        format.html
        format.json do
          @index = WorkplaceCounts::Index.new

          if @index.run
            render json: @index.data
          else
            render json: { full_messages: 'Обратитесь к администратору, т.***REMOVED***' }, status: 422
          end
        end
      end
    end

    def create
      @create = WorkplaceCounts::Create.new(workplace_count_params)

      if @create.run
        render json: { full_message: "Отдел #{@create.data.division} добавлен." }
      else
        render json: @create.error, status: 422
      end
    end

    def show
      @workplace_count = WorkplaceCount
                           .includes(:workplace_responsibles, :user_isses)
                           .select('invent_workplace_count.*')
                           .where(workplace_count_id: params[:workplace_count_id])
                           .first

      @workplace_count = @workplace_count.as_json(
        include: {
          workplace_responsibles: {
            include: {
              user_iss: { only: %i[id_tn tn fio_initials] }
            }
          }
        }
      )

      @workplace_count['workplace_responsibles'] = @workplace_count['workplace_responsibles'].each do |resp|
        resp['id'] = resp['workplace_responsible_id']
        resp['tn'] = resp['user_iss']['tn']
        resp['fio'] = resp['user_iss']['fio_initials']

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
        render json: { object: @workplace_count.errors, full_message: "Ошибка. #{@workplace_count.errors
          .full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    end

    def destroy
      if @workplace_count.destroy
        render json: { full_message: 'Отдел удален.' }, status: :ok
      else
        render json: { full_message: "Ошибка. #{@workplace_count.errors.full_messages.join(', ')}" }, status:
          :unprocessable_entity
      end
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
        users_attributes: %i[
          id
          tn
          phone
          _destroy
        ]
      )
    end
  end
end
