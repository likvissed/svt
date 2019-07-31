module Warehouse
  class ItemsController < Warehouse::ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Items::Index.new(params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def edit
      edit_item = Items::Edit.new(params[:id])

      if edit_item.run
        render json: edit_item.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def update
      update_item = Items::Update.new(params[:id], item_params)

      if update_item.run
        render json: { full_message: I18n.t('controllers.warehouse/item.updated') }
      else
        render json: update_item.error, status: 422
      end
    end

    # def destroy
    #   @destroy = Items::Destroy.new(current_user, params[:id])

    #   if @destroy.run
    #     render json: { full_message: I18n.t('controllers.warehouse/item.destroyed') }
    #   else
    #     render json: { full_message: @destroy.error[:full_message] }, status: 422
    #   end
    # end

    protected

    def item_params
      params.require(:item).permit(policy(Item).permitted_attributes)
    end
  end
end
