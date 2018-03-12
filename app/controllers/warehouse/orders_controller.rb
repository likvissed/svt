module Warehouse
  class OrdersController < ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Orders::Index.new(params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def new
      @new_order = Orders::NewOrder.new(params[:operation])

      if @new_order.run
        render json: @new_order.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def create_in
      @create_in = Orders::CreateIn.new(current_user, order_params, params[:done])

      if @create_in.run
        render json: { full_message: I18n.t('controllers.warehouse/order.created_in', count: @create_in.data) }
      else
        render json: @create_in.error, status: 422
      end
    end

    def create_out
      @create_out = Orders::CreateOut.new(current_user, order_params)

      if @create_out.run
        render json: { full_message: I18n.t('controllers.warehouse/order.created_out') }
      else
        render json: @create_out.error, status: 422
      end
    end

    def edit
      @edit = Orders::Edit.new(params[:id])

      if @edit.run
        render json: @edit.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def update_in
      @update_in = Orders::UpdateIn.new(current_user, params[:id], order_params)

      if @update_in.run
        render json: { full_message: I18n.t('controllers.warehouse/order.updated', order_id: params[:id]) }
      else
        render json: @update_in.error, status: 422
      end
    end

    def update_out
      @update_out = Orders::UpdateOut.new(current_user, params[:id], order_params)

      if @update_out.run
        render json: { full_message: I18n.t('controllers.warehouse/order.updated', order_id: params[:id]) }
      else
        render json: @update_out.error, status: 422
      end
    end

    def execute_in
      @execute_in = Orders::ExecuteIn.new(current_user, params[:id], order_params)

      if @execute_in.run
        render json: { full_message: I18n.t('controllers.warehouse/order.executed') }
      else
        render json: @execute_in.error, status: 422
      end
    end

    def execute_out
      @execute_out = Orders::ExecuteOut.new(current_user, params[:id], order_params)

      if @execute_out.run
        render json: { full_message: I18n.t('controllers.warehouse/order.executed') }
      else
        render json: @execute_out.error, status: 422
      end
    end

    def destroy
      @destroy = Orders::Destroy.new(params[:id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.warehouse/order.destroyed') }
      else
        render json: { full_message: @destroy.data }, status: 422
      end
    end

    def prepare_to_deliver
      @deliver = Orders::PrepareToDeliver.new(current_user, params[:id], order_params)

      if @deliver.run
        render json: @deliver.data
      else
        render json: @deliver.error, status: 422
      end
    end

    private

    def order_params
      params.require(:order).permit(
        :id,
        :invent_workplace_id,
        :creator_id_tn,
        :consumer_id_tn,
        :consumer_tn,
        :validator_id_tn,
        :operation,
        :status,
        :creator_fio,
        :consumer_fio,
        :validator_fio,
        :consumer_dept,
        :comment,
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
          inv_item_ids: [],
          inv_items_attributes: [
            :id,
            :serial_num,
            :invent_num,
            :_destroy
          ]
        ]
      )
    end
  end
end
