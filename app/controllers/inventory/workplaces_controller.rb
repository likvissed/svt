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

    def pc_config_from_audit
      @pc_config = LkInvents::PcConfigFromAudit.new(params[:invent_num])

      if @pc_config.run
        render json: @pc_config.data
      else
        render json: { full_message: @pc_config.errors.full_messages.join('. ') }, status: 422
      end
    end

    def edit
      @edit = Workplaces::Edit.new(current_user, params[:workplace_id])

      respond_to do |format|
        format.html do
          if @edit.run(request.format.symbol)
            @workplace = @edit.data
          end
        end
        format.json do
          if @edit.run(request.format.symbol)
            render json: @edit.data
          else
            render json: { full_message: 'Обратитесь к администратору, т.***REMOVED***' }, status: 422
          end
        end
      end
    end

    def update
      @workplace = LkInvents::UpdateWorkplace.new(
        current_user, params[:workplace_id], workplace_params, params[:pc_file]
      )

      if @workplace.run
        flash[:notice] = 'Данные о рабочем месте обновлены'
        render json: { location: inventory_workplaces_path }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def send_pc_script
      send_file(Rails.root.join('public', 'downloads', 'SysInfo.exe'), disposition: 'attachment')
    end

    private

    def workplace_params
      params[:workplace] = JSON.parse(params[:workplace])
      params.require(:workplace).permit(
        :workplace_count_id,
        :workplace_type_id,
        :workplace_specialization_id,
        :id_tn,
        :location_site_id,
        :location_building_id,
        :location_room_name,
        :location_room_id,
        :comment,
        :status,
        inv_items_attributes: [
          :id,
          :parent_id,
          :type_id,
          :model_id,
          :item_model,
          :workplace_id,
          :location,
          :invent_num,
          :_destroy,
          inv_property_values_attributes: %i[
            id
            property_id
            item_id
            property_list_id
            value
            _destroy
          ]
        ]
      )
    end
  end
end
