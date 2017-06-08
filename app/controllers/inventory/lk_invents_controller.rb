# require './app/services/inventory/init_properties.rb'

module Inventory
  class LkInventsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token
    before_action :check_***REMOVED***_authorization
    after_action -> { sign_out @***REMOVED***_auth.data[:user] }

    respond_to :json

    def init_properties
      @properties = LkInvents::InitProperties.new(current_user)

      if @properties.run
        render json: @properties.data
      else
        render json: { full_message: 'Обратитесь к администратору, т.***REMOVED***' }, status: 422
      end
    end

    def show_division_data
      @division = LkInvents::ShowDivisionData.new(current_user, params[:division])

      if @division.run
        render json: @division.data
      else
        render json: { full_message: 'Обратитесь к администратору, т.***REMOVED***' }, status: 422
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

    def create_workplace
      @workplace = LkInvents::CreateWorkplace.new(current_user, workplace_params, params[:pc_file])

      if @workplace.run
        render json: { workplace: @workplace.data, full_message: 'Рабочее место создано' }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def edit_workplace
      @workplace = LkInvents::EditWorkplace.new(current_user, params[:workplace_id])

      if @workplace.run
        render json: @workplace.data
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def update_workplace
      @workplace = LkInvents::UpdateWorkplace.new(
        current_user, params[:workplace_id], workplace_params, params[:pc_file]
      )

      if @workplace.run
        render json: { workplace: @workplace.data, full_message: 'Данные о рабочем месте обновлены' }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def destroy_workplace
      @workplace = LkInvents::DestroyWorkplace.new(current_user, params[:workplace_id])

      if @workplace.run
        render json: { full_message: 'Рабочее место удалено' }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def generate_pdf
      @workplace_count = WorkplaceCount
                           .includes(
                             workplaces: [
                               :iss_reference_site,
                               :iss_reference_building,
                               :iss_reference_room,
                               :workplace_type,
                               :user_iss, { inv_items: :inv_type }
                             ]
                           )
                           .find_by(division: params[:division])
      authorize @workplace_count, :generate_pdf?

      render pdf: 'test',
             template: 'templates/workplace_list.haml',
             locals: { workplace_count: @workplace_count },
             encoding: 'UTF-8'
      # disposition: 'attachment'
    end

    def send_pc_script
      send_file(Rails.root.join('public', 'downloads', 'SysInfo.exe'), disposition: 'attachment')
    end

    private

    # Проверить SID в таблице user_sessions, чтобы знать, действительно ли пользователь авторизован в ЛК.
    def check_***REMOVED***_authorization
      @***REMOVED***_auth = LkInvents::LkAuthorization.new(params[:sid])

      if @***REMOVED***_auth.run
        sign_in @***REMOVED***_auth.data[:user]
      else
        render json: { full_message: @***REMOVED***_auth.errors.full_messages.join('. ') }, status: 403
      end
    end

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
