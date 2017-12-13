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
            render json: { full_message: 'Ошибка. Обратитесь к администратору, т.***REMOVED***' }, status: 422
          end
        end
      end
    end

    def new
      @new_order = Orders::NewOrder.new(params[:operation])

      if @new_order.run
        render json: @new_order.data
      else
        render json: { full_message: 'Ошибка. Обратитесь к администратору (т.***REMOVED***)' }, status: 422
      end
    end

    def create
      @create = Orders::Create.new(current_user, order_params)

      if @create.run
        render json: @create.data
      else
        # render json: { full_message: @create.errors.full_messages.join('. ') }, status: 422
        render json: @create.error, status: 422
      end
    end

    private

    def order_params
      params.require(:order).permit(
        :warehouse_order_id,
        :workplace_id,
        :creator_id_tn,
        :consumer_id_tn,
        :validator_id_tn,
        :operation,
        :status,
        :creator_fio,
        :consumer_fio,
        :validator_fio,
        :consumer_dept,
        :comment,
        item_to_orders_attributes: [
          :id,
          :order_id,
          :invent_item_id,
          :_destroy
        ]
      )
    end
  end
end
