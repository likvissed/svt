module Warehouse
  class ItemsController < ApplicationController
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

    def destroy
      @destroy = Items::Destroy.new(params[:id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.warehouse/item.destroyed') }
      else
        render json: { full_message: @destroy.data }, status: 422
      end
    end
  end
end
