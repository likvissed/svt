module Invent
  class WorkplacesController < ApplicationController
    before_action :check_access

    def index
      respond_to do |format|
        format.html
        format.json do
          @index = Workplaces::Index.new(current_user, params)

          if @index.run
            render json: @index.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def new
      respond_to do |format|
        format.html do
          authorize Workplace.new
          session[:workplace_prev_url] = request.referrer
        end
        format.json do
          @new_wp = Workplaces::NewWp.new(current_user)

          if @new_wp.run
            render json: @new_wp.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def create
      @create = Workplaces::Create.new(current_user, workplace_params)

      if @create.run
        flash[:notice] = I18n.t('controllers.invent/workplace.created')
        # session[:workplace_prev_url]
        render json: { location: invent_workplaces_path }
      else
        render json: { full_message: @create.error[:full_message] }, status: 422
      end
    end

    def list_wp
      respond_to do |format|
        format.html
        format.json do
          @list_wp = Workplaces::ListWp.new(params[:init_filters], params[:filters])

          if @list_wp.run
            render json: @list_wp.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def pc_config_from_audit
      @pc_config = Workplaces::PcConfigFromAudit.new(params[:invent_num])

      if @pc_config.run
        render json: @pc_config.data
      else
        render json: { full_message: @pc_config.errors.full_messages.join('. ') }, status: 422
      end
    end

    def pc_config_from_user
      @pc_file = Workplaces::PcConfigFromUser.new(params[:pc_file])

      if @pc_file.run
        render json: { data: @pc_file.data, full_message: I18n.t('controllers.invent/workplace.pc_config_processed') }
      else
        render json: { full_message: @pc_file.error[:full_message] }, status: 422
      end
    end

    def edit
      @edit = Workplaces::Edit.new(current_user, params[:workplace_id])

      respond_to do |format|
        format.html do
          @workplace = @edit.data if @edit.run(request.format.symbol)
          session[:workplace_prev_url] = request.referrer
        end
        format.json do
          if @edit.run(request.format.symbol)
            render json: @edit.data
          else
            render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
          end
        end
      end
    end

    def update
      @update = Workplaces::Update.new(current_user, params[:workplace_id], workplace_params)

      if @update.run
        flash[:notice] = I18n.t('controllers.invent/workplace.updated')
        render json: { location: session[:workplace_prev_url] }
      else
        render json: { full_message: @update.error[:full_message] }, status: 422
      end
    end

    def destroy
      @destroy = Workplaces::Destroy.new(current_user, params[:workplace_id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.invent/workplace.destroyed') }
      else
        render json: { full_message: @destroy.error[:full_message] }, status: 422
      end
    end

    def hard_destroy
      @hard_destroy = Workplaces::HardDestroy.new(current_user, params[:workplace_id])

      if @hard_destroy.run
        flash[:notice] = I18n.t('controllers.invent/workplace.destroyed')
        render json: { location: session[:workplace_prev_url] }
      else
        render json: { full_message: @hard_destroy.error[:full_message] }, status: 422
      end
    end

    def confirm
      @confirm = Workplaces::Confirm.new(current_user, params[:type], params[:ids])

      if @confirm.run
        render json: { full_message: @confirm.data }
      else
        render json: { full_message: @confirm.errors.full_messages.join('. ') }, status: 422
      end
    end

    def send_pc_script
      send_file(Rails.root.join('public', 'downloads', 'SysInfo.exe'), disposition: 'attachment')
    end

    protected

    def workplace_params
      params.require(:workplace).permit(policy(Workplace).permitted_attributes)
      # params.require(:workplace).permit(
      #   :workplace_id,
      #   :enabled_filters,
      #   :workplace_count_id,
      #   :workplace_type_id,
      #   :workplace_specialization_id,
      #   :id_tn,
      #   :location_site_id,
      #   :location_building_id,
      #   :location_room_name,
      #   :location_room_id,
      #   :comment,
      #   :status,
      #   item_ids: [],
      #   items_attributes: [
      #     :id,
      #     :parent_id,
      #     :type_id,
      #     :model_id,
      #     :item_model,
      #     :workplace_id,
      #     :location,
      #     :invent_num,
      #     :serial_num,
      #     :status,
      #     :_destroy,
      #     property_values_attributes: %i[id property_id item_id property_list_id value _destroy]
      #   ]
      # )
    end

    def check_access
      authorize [:invent, :workplace], :ctrl_access?
    end
  end
end
