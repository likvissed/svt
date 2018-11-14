module Invent
  class ItemsController < ApplicationController
    before_action :check_access, except: [:pc_config_from_audit, :pc_config_from_user]

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

    def busy
      @busy = Items::Busy.new(params[:type_id], params[:invent_num], params[:item_id], params[:division])

      if @busy.run
        render json: @busy.data
      else
        render json: { full_message: @busy.errors.full_messages.join('. ') }, status: 422
      end
    end

    def show
      @show = Items::Show.new({ item_id: params[:item_id] })

      if @show.run
        render json: @show.data.first
      else
        render json: { full_message: @show.error[:full_message] }, status: 422
      end
    end

    def edit
      @edit = Items::Edit.new(params[:item_id], params[:with_init_props])

      if @edit.run
        render json: @edit.data
      else
        render json: { full_message: @edit.error[:full_message] }, status: 422
      end
    end

    def update
      @update = Items::Update.new(current_user, params[:item_id], item_params)

      if @update.run
        render json: { full_message: I18n.t('controllers.invent/item.updated', item_id: params[:id]) }
      else
        render json: @update.error, status: 422
      end
    end

    def avaliable
      @avaliable = Items::Avaliable.new(params[:type_id])

      if @avaliable.run
        render json: @avaliable.data
      else
        render json: { full_message: I18n.t('controllers.app.unprocessable_entity') }, status: 422
      end
    end

    def destroy
      @destroy = Items::Destroy.new(current_user, params[:item_id])

      if @destroy.run
        render json: @destroy.data
      else
        render json: { full_message: @destroy.error[:full_message] }, status: 422
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
        render json: { data: @pc_file.data, full_message: I18n.t('controllers.invent/workplace.pc_config_processed') }
      else
        render json: { full_message: @pc_file.error[:full_message] }, status: 422
      end
    end

    def to_stock
      @to_stock = Items::ToStock.new(current_user, params[:item_id])

      if @to_stock.run
        render json: { full_message: I18n.t('controllers.invent/item.sended_to_stock', item_id: params[:id]) }
      else
        render json: @to_stock.error, status: 422
      end
    end

    protected

    def check_access
      authorize [:invent, :item], :ctrl_access?
    end

    def item_params
      params.require(:item).permit(policy(Item).permitted_attributes)
    end
  end
end
