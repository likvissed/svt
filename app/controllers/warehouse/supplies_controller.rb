module Warehouse
  class SuppliesController < Warehouse::ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Supplies::Index.new(params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def new
      @new_supply = Supplies::NewSupply.new(current_user)

      if @new_supply.run
        render json: @new_supply.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def create
      @create = Supplies::Create.new(current_user, supply_params)

      if @create.run
        render json: { full_message: I18n.t('controllers.warehouse/supply.created') }
      else
        render json: @create.error, status: 422
      end
    end

    def edit
      @edit = Supplies::Edit.new(current_user, params[:id])

      if @edit.run
        render json: @edit.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def update
      @update = Supplies::Update.new(current_user, params[:id], supply_params)

      if @update.run
        render json: { full_message: I18n.t('controllers.warehouse/supply.updated', supply_id: params[:id]) }
      else
        render json: @update.error, status: 422
      end
    end

    def destroy
      @destroy = Supplies::Destroy.new(current_user, params[:id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.warehouse/supply.destroyed') }
      else
        render json: { full_message: @destroy.error[:full_message] }, status: 422
      end
    end

    protected

    def supply_params
      params.require(:supply).permit(
        :id,
        :name,
        :supplyer,
        :comment,
        :date,
        operations_attributes: [
          :id,
          :item_id,
          :location_id,
          :stockman_id_tn,
          :operationable_id,
          :operationable_type,
          :item_type,
          :item_model,
          :shift,
          :stockman_fio,
          :status,
          :date,
          :_destroy,
          item: [
            :id,
            :invent_type_id,
            :invent_model_id,
            :warehouse_type,
            :item_type,
            :item_model,
            :barcode
          ]
        ]
      )
    end
  end
end
