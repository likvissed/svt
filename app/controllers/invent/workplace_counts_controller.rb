module Invent
  class WorkplaceCountsController < ApplicationController
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
        render json: { full_message: "Отдел #{@create.data.division} добавлен" }
      else
        render json: @create.error, status: 422
      end
    end

    def show
      @show = WorkplaceCounts::Show.new(params[:workplace_count_id])

      if @show.run
        render json: @show.data
      else
        render json: { full_message: @show.errors.full_messages.join('. ') }, status: 422
      end
    end

    def update
      @update = WorkplaceCounts::Update.new(params[:workplace_count_id], workplace_count_params)

      if @update.run
        render json: { full_message: "Данные одела #{@update.data.division} обновлены" }
      else
        render json: @update.error, status: 422
      end
    end

    def destroy
      @workplace_count = WorkplaceCount.find(params[:workplace_count_id])

      if @workplace_count.destroy
        render json: { full_message: 'Отдел удален' }
      else
        render json: { full_message: "Ошибка. #{@workplace_count.errors.full_messages.join(', ')}" }, status: 422
      end
    end

    private

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
