module Warehouse
  class OrdersController < Warehouse::ApplicationController
    def index_in
      respond_to do |format|
        format.html
        format.json do
          @index = Orders::Index.new(params, operation: :in, status: :processing)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def index_out
      respond_to do |format|
        format.html
        format.json do
          @index = Orders::Index.new(params, operation: :out, status: :processing)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def index_write_off
      respond_to do |format|
        format.html
        format.json do
          @index = Orders::Index.new(params, operation: :write_off, status: :processing)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def archive
      respond_to do |format|
        format.html
        format.json do
          @index = Orders::Index.new(params, status: :done)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def new
      @new_order = Orders::NewOrder.new(current_user, params[:operation])

      if @new_order.run
        render json: @new_order.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def create_in
      @create_in = Orders::CreateIn.new(current_user, order_params)

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

    def create_write_off
      @create_write_off = Orders::CreateWriteOff.new(current_user, order_params)

      if @create_write_off.run
        render json: { full_message: I18n.t('controllers.warehouse/order.created_write_off') }
      else
        render json: @create_write_off.error, status: 422
      end
    end

    def edit
      @edit = Orders::Edit.new(params[:id], params[:check_unreg])

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

    def update_write_off
      @update_write_off = Orders::UpdateWriteOff.new(current_user, params[:id], order_params)

      if @update_write_off.run
        render json: { full_message: I18n.t('controllers.warehouse/order.updated', order_id: params[:id]) }
      else
        render json: @update_write_off.error, status: 422
      end
    end

    def confirm
      @confirm = Orders::Confirm.new(current_user, params[:id])

      if @confirm.run
        render json: { full_message: I18n.t('controllers.warehouse/order.confirmed', order_id: params[:id]) }
      else
        render json: @confirm.error, status: 422
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

    def execute_write_off
      @execute_write_off = Orders::ExecuteWriteOff.new(current_user, params[:id], order_params)

      if @execute_write_off.run
        render json: { full_message: I18n.t('controllers.warehouse/order.executed') }
      else
        render json: @execute_write_off.error, status: 422
      end
    end

    def destroy
      @destroy = Orders::Destroy.new(current_user, params[:id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.warehouse/order.destroyed') }
      else
        render json: { full_message: @destroy.error[:full_message] }, status: 422
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

    def print
      @print = Orders::Print.new(current_user, params[:id], params[:order])

      if @print.run
        send_data @print.data.read, filename: "#{params[:id]}.rtf", type: "application/rtf", disposition: "attachment"
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    private

    def order_params
      params.require(:order).permit(policy(Order).permitted_attributes)
    end
  end
end
