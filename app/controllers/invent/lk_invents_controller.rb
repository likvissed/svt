module Invent
  class LkInventsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token
    # skip_before_action :authorization
    before_action :check_***REMOVED***_authorization, except: %i[svt_access existing_item invent_item]
    # after_action -> { sign_out @***REMOVED***_auth.data }, except: :svt_access

    respond_to :json

    def svt_access
      @svt_access = LkInvents::SvtAccess.new(params[:tn])

      if @svt_access.run
        render json: @svt_access.data
      else
        render json: { full_message: I18n.t('controllers.***REMOVED***_invents.unprocessable_entity') }, status: 422
      end
    end

    def init_properties
      @properties = LkInvents::InitProperties.new(current_user)

      if @properties.run
        render json: @properties.data
      elsif @properties.data[:divisions].nil?
        raise Pundit::NotAuthorizedError, 'Access denied'
      else
        render json: { full_message: I18n.t('controllers.***REMOVED***_invents.unprocessable_entity') }, status: 422
      end
    end

    def show_division_data
      @division = LkInvents::ShowDivisionData.new(current_user, params[:division])

      if @division.run
        render json: @division.data
      else
        render json: { full_message: I18n.t('controllers.***REMOVED***_invents.unprocessable_entity') }, status: 422
      end
    end

    def pc_config_from_audit
      @pc_config = Items::PcConfigFromAudit.new(params[:invent_num])

      if @pc_config.run
        render json: @pc_config.data
      else
        render json: { full_message: @pc_config.errors.full_messages.join('. ') }, status: 422
      end
    end

    def pc_config_from_user
      @pc_file = Items::PcConfigFromUser.new(params[:pc_file])

      if @pc_file.run
        render json: { data: @pc_file.data, full_message: I18n.t('controllers.***REMOVED***_invents.file_added') }
      else
        render json: { full_message: @pc_file.errors.full_messages.join('. ') }, status: 422
      end
    end

    def create_workplace
      @workplace = Workplaces::Create.new(current_user, workplace_params)

      if @workplace.run
        render json: { workplace: @workplace.data, full_message: I18n.t('controllers.invent/workplace.created') }
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
      @workplace = Workplaces::Update.new(current_user, params[:workplace_id], workplace_params)

      if @workplace.run
        render json: { workplace: @workplace.data, full_message: I18n.t('controllers.invent/workplace.updated') }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def destroy_workplace
      @workplace = LkInvents::DestroyWorkplace.new(current_user, params[:workplace_id])

      if @workplace.run
        render json: { full_message: I18n.t('controllers.invent/workplace.destroyed') }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def generate_pdf
      # @workplace_count = WorkplaceCount.find_by(division: params[:division])
      # authorize @workplace_count, :generate_pdf?
      #
      # render pdf: "Перечень рабочих мест отдела #{@workplace_count.division}",
      #        template: 'templates/approved_workplace_list',
      #        locals: { workplace_count: @workplace_count },
      #        encoding: 'UTF-8'
      # disposition: 'attachment'

      @division_report = LkInvents::DivisionReport.new(params[:division])
      if @division_report.run
        send_data @division_report.data.read,
                  filename: "#{@division_report.wp[:workplace_count]['division']}.rtf",
                  type: "application/rtf",
                  disposition: "attachment"
      else
        render json: { full_message: I18n.t('controllers.***REMOVED***_invents.unprocessable_entity') }, status: 422
      end
    end

    def send_pc_script
      send_file(Rails.root.join('public', 'downloads', 'SysInfo.exe'), disposition: 'attachment')
    end

    def existing_item
      @existing_item = Items::ExistingItem.new(Type::ALL_PRINT_TYPES, params[:invent_num])

      if @existing_item.run
        render json: @existing_item.data
      else
        render json: { full_message: 'Обратитесь к администратору, т.***REMOVED***' }, status: 422
      end
    end

    def invent_item
      @show = Invent::Items::Show.new({ invent_num: params[:invent_num], type_id: params[:type_id] })

      if @show.run
        render json: @show.data
      else
        render json: { full_message: @show.error[:full_message] }, status: 422
      end
    end

    private

    # Проверить SID в таблице user_sessions, чтобы знать, действительно ли пользователь авторизован в ЛК.
    def check_***REMOVED***_authorization
      @***REMOVED***_auth = LkInvents::LkAuthorization.new(params[:sid])

      if @***REMOVED***_auth.run
        sign_in @***REMOVED***_auth.data
      else
        render json: { full_message: @***REMOVED***_auth.errors.full_messages.join('. ') }, status: 403
      end
    end

    def workplace_params
      params.require(:workplace).permit(
        :workplace_count_id,
        :workplace_type_id,
        :workplace_specialization_id,
        :id_tn,
        :location_site_id,
        :location_building_id,
        :location_room_id,
        :comment,
        :status,
        items_attributes: [
          :id,
          :parent_id,
          :type_id,
          :model_id,
          :item_model,
          :workplace_id,
          :location,
          :invent_num,
          :_destroy,
          property_values_attributes: %i[id property_id item_id property_list_id value _destroy]
        ]
      )
    end
  end
end
