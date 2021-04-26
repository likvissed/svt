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
          # session[:workplace_prev_url] = request.referrer
          session[:workplace_prev_url] = invent_workplaces_path
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
      workplace_attachments = params[:attachments].presence || []
      @create = Workplaces::Create.new(current_user, workplace_params, workplace_attachments)

      if @create.run
        flash[:notice] = I18n.t('controllers.invent/workplace.created')
        # session[:workplace_prev_url]
        render json: { location: invent_workplaces_path }
      else
        render json: { full_message: @create.error[:full_message] }, status: 422
      end
    end

    def list_wp
      @list_wp = Workplaces::ListWp.new(current_user, params)

      if @list_wp.run
        render json: @list_wp.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def edit
      @edit = Workplaces::Edit.new(current_user, params[:workplace_id])

      respond_to do |format|
        format.html do
          @workplace = @edit.data if @edit.run(request.format.symbol)
          # session[:workplace_prev_url] = request.referrer
          session[:workplace_prev_url] = invent_workplaces_path
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
      workplace_attachments = params[:attachments].presence || []
      @update = Workplaces::Update.new(current_user, params[:workplace_id], workplace_params, workplace_attachments)

      if @update.run
        flash[:notice] = I18n.t('controllers.invent/workplace.updated')
        render json: { location: invent_workplaces_path }
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
        render json: { location: invent_workplaces_path }
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

    def category_for_room
      room = IssReferenceRoom.find_by(name: params[:room_name], building_id: params[:building_id])
      room_is_new = false

      category_id = if room.present?
                      room.security_category_id
                    else
                      room_is_new = true if params[:room_name] != ''
                      RoomSecurityCategory.missing_category.id
                    end

      render json: { category_id: category_id, room_is_new: room_is_new }
    end

    protected

    def workplace_params
      new_params = ActionController::Parameters.new({ workplace: JSON.parse(params[:workplace]) })
      new_params.require(:workplace).permit(policy(Workplace).permitted_attributes)
    end

    def check_access
      authorize [:invent, :workplace], :ctrl_access?
    end
  end
end
