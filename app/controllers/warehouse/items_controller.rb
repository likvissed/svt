module Warehouse
  class ItemsController < Warehouse::ApplicationController
    before_action :check_access

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
      edit_item = Items::Edit.new(current_user, params[:id])

      if edit_item.run
        render json: edit_item.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def update
      update_item = Items::Update.new(current_user, params[:id], item_params)

      if update_item.run
        render json: { full_message: I18n.t('controllers.warehouse/item.updated'), data: update_item.data }
      else
        render json: update_item.error, status: 422
      end
    end

    def split
      split_items = Items::Split.new(current_user, params[:id], params[:items])

      if split_items.run
        render json: { full_message: I18n.t('controllers.warehouse/item.splited') }
      else
        render json: split_items.error, status: 422
      end
    end

    def create
      create_item = Items::Create.new(current_user, item_params)

      if create_item.run
        render json: { full_message: I18n.t('controllers.warehouse/item.create') }
      else
        render json: create_item.error, status: 422
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

    def check_access
      authorize %i[warehouse item], :ctrl_access?
    end

    def item_params
      w_item_params = params.require(:item).permit(policy(Item).permitted_attributes)
      w_item_params[:location_attributes] = w_item_params.delete :location
      w_item_params.permit!
    end
  end
end
