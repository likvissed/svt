module Invent
  class WorkplaceCountsController < ApplicationController
    before_action :check_access

    def index
      respond_to do |format|
        format.html
        format.json do
          @index = WorkplaceCounts::Index.new

          if @index.run
            render json: @index.data
          else
            render json: { full_messages: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def create
      @create = WorkplaceCounts::Create.new(workplace_count_params)

      if @create.run
        render json: { full_message: I18n.t('controllers.invent/workplace_count.created', dept: @create.data.division) }
      else
        render json: @create.error, status: 422
      end
    end

    def create_list
      @create_list = WorkplaceCounts::CreateList.new(params[:file])

      if @create_list.run
        render json: { full_message: I18n.t('controllers.invent/workplace_count.list_created') }
      else
        render json: { full_message: @create_list.errors.full_messages.join('. ') }, status: 422
      end
    end

    def show
      @show = WorkplaceCounts::Show.new(params[:workplace_count_id])

      if @show.run
        render json: @show.data
      else
        render json: { full_message: @show.error[:full_message] }, status: 422
      end
    end

    def update
      @update = WorkplaceCounts::Update.new(params[:workplace_count_id], workplace_count_params)

      if @update.run
        render json: { full_message: I18n.t('controllers.invent/workplace_count.updated', dept: @update.data.division) }
      else
        render json: @update.error, status: 422
      end
    end

    def destroy
      @workplace_count = WorkplaceCount.find(params[:workplace_count_id])

      if @workplace_count.destroy
        render json: { full_message: I18n.t('controllers.invent/workplace_count.destroyed') }
      else
        render json: { full_message: "Ошибка. #{@workplace_count.errors.full_messages.join(', ')}" }, status: 422
      end
    end

    protected

    def workplace_count_params
      params.require(:workplace_count).permit(
        :workplace_count_id,
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

    def check_access
      authorize [:invent, :workplace_count], :ctrl_access?
    end
  end
end
