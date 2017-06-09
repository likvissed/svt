module Inventory
  class WorkplacesController < ApplicationController
    protect_from_forgery except: :create

    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Workplaces::Index.new

          if @index.run
            render json: @index.data
          else
            render json: { full_messages: 'Обратитесь к администратору, т.***REMOVED***' }, status: 422
          end
        end
      end
    end

    def edit
      @wp = SingleWorkplaceService.new(params[:workplace_id])

      respond_to do |format|
        format.html { @workplace = @wp.workplace }
        format.json do
          @prop_service = InitPropertiesService.new(nil, @wp.workplace.division)
          @prop_service.run
          @wp.transform
          render json: { prop_data: @prop_service.data, wp_data: @wp.workplace }, status: 200
        end
      end
    end

    private

    def workplace_params
      params.require(:workplace).permit(
        :workplace_count_id,
        :workplace_type_id,
        :id_tn,
        :location,
        :comment,
        :status,
        inv_items_attributes: [
          :id,
          :parent_id,
          :type_id,
          :workplace_id,
          :location,
          :model_name,
          :invent_num,
          :_destroy,
          inv_property_values_attributes: %i[
            id
            property_id
            item_id
            value
            _destroy
          ]
        ]
      )
    end
  end
end
