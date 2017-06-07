# require './app/services/inventory/init_properties.rb'

module Inventory
  class LkInventsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token
    before_action :check_***REMOVED***_authorization
    # authorize_resource class: false, param_method: :workplace_params
    # before_action :check_workplace_count_access, only: %i[create_workplace edit_workplace update_workplace delete_workplace]
    # before_action :check_timeout, except: %i[init_properties show_division_data pc_config_from_audit send_pc_script]
    # after_action :verify_authorized, except: %i[init_properties pc_config_from_audit]
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

    def delete_workplace
      @workplace = LkInvents::DeleteWorkplace.new(params[:workplace_id])

      if @workplace.run
        render json: { full_message: 'Рабочее место удалено' }
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
      end
    end

    def generate_pdf
      @workplace_count = WorkplaceCount
                           .includes(workplaces: [:workplace_type, :user_iss, { inv_items: :inv_type }])
                           .where(division: params[:division])
                           .first

      render pdf: 'test',
             template: 'templates/workplace.haml',
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

    # Проверить, есть ли у пользователя доступ на создание/редактирование/удаление рабочих мест указанного отдела.
    def check_workplace_count_access
      params[:workplace] = JSON.parse(params[:workplace])
      # unless params[:workplace]
      #   render json: { full_message: 'Доступ запрещен' }, status: 403
      #   return
      # end

      # workplace_count
      # if @workplace_count
      #   unless @workplace_count.workplace_responsibles.any? { |resp| resp.id_tn == session[:id_tn] }
      #     render json: { full_message: 'Доступ запрещен' }, status: 403
      #   end
      # end
    end

    # Проверить, прошло ли разрешенное время редактирования для указанного отдела.
    def check_timeout
      # Для случаев, когда workplace_id существует (например, редактирование или удаление записи)
      if params[:workplace_id]
        workplace
        unless time_not_passed?(@workplace.workplace_count.time_start, @workplace.workplace_count.time_end)
          render json: { full_message: "Время для работы с отделом #{@workplace.workplace_count.division} истекло" },
                 status: 403

          return false
        end
        # Для случаев, когда workplace_id не существует (создается новая запись), но задан workplace_count_id
      elsif params[:workplace] && params[:workplace][:workplace_count_id]
        workplace_count

        unless time_not_passed?(@workplace_count.time_start, @workplace_count.time_end)
          render json: { full_message: "Время для работы с отделом #{@workplace_count.division} истекло" }, status: 403

          return false
        end
        # Для случая, когда задан отдел, запрос отправлен для генерации PDF. Здесь, наоборот, необходимо разрешить
        # доступ, только если прошло разрешенное время редактирования.
      elsif params[:division]
=begin
      @workplace_count = WorkplaceCount.find_by(division: params[:division])

      if (time_not_passed?(@workplace_count.time_start, @workplace_count.time_end))
        render json: { full_message: "Время для работы с отделом #{@workplace_count.division} не истекло.  Экспорт в PDF
файл станет доступен #{@workplace_count.time_end + 1.day}" }, status: 403

        return false
      end
=end
      else
        render json: { full_message: 'Доступ запрещен, так как не удается определить, к какому отделу относится
 запрашиваемая операция. Обратитесь к администратору' }, status: 403

        false
      end
    end

    # Проверка, входит ли текущее время в указанный интервал (true - если входит).
    def time_not_passed?(time_start, time_end)
      Time.zone.today >= time_start && Time.zone.today <= time_end
    end

    # Создать переменную @workplace_count, если она не существует.
    def workplace_count
      @workplace_count = WorkplaceCount.find(params[:workplace][:workplace_count_id]) unless @workplace_count
    end

    # Создать переменную @workplace, если она не существует.
    def workplace
      @workplace = Workplace.find(params[:workplace_id]) unless @workplace
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
