module Invent
  class ModelsController < ApplicationController
    before_action :check_access

    cache_sweeper :cache_sweeper

    def index
      @index = Models::Index.new(params)

      if @index.run
        render json: @index.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def new
      @new_model = Models::NewModel.new

      if @new_model.run
        render json: @new_model.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def create
      @create = Models::Create.new(model_params)

      if @create.run
        render json: { full_message: I18n.t('controllers.invent/model.created') }
      else
        render json: @create.error, status: 422
      end
    end

    def edit
      @edit = Models::Edit.new(params[:model_id])

      if @edit.run
        render json: @edit.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def update
      @update = Models::Update.new(params[:model_id], model_params)

      if @update.run
        render json: { full_message: I18n.t('controllers.invent/model.updated') }
      else
        render json: @update.error, status: 422
      end
    end

    def destroy
      @destroy = Models::Destroy.new(params[:model_id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.invent/model.destroyed') }
      else
        render json: { full_message: @destroy.error[:full_message] }, status: 422
      end
    end

    protected

    def model_params
      params.require(:model).permit(
        :model_id,
        :vendor_id,
        :type_id,
        :item_model,
        model_property_lists_attributes: [
          :id,
          :model_id,
          :property_id,
          :property_list_id,
          :_destroy
        ]
      )
    end

    def check_access
      authorize [:invent, :model], :ctrl_access?
    end
  end
end
