module Invent
  class VendorsController < ApplicationController
    def index
      respond_to do |format|
        format.html
        format.json do
          @vendors = Vendor.all.order(:vendor_name)

          render json: @vendors
        end
      end
    end

    def create
      @create = Vendors::Create.new(vendor_params)

      if @create.run
        render json: { full_message: I18n.t('controllers.invent/vendor.created') }
      else
        render json: @create.error, status: 422
      end
    end

    def destroy
      @destroy = Vendors::Destroy.new(params[:vendor_id])

      if @destroy.run
        render json: { full_message: I18n.t('controllers.invent/vendor.destroyed') }
      else
        render json: { full_message: @destroy.error }, status: 422
      end
    end

    protected

    def vendor_params
      params.require(:vendor).permit(:vendor_name)
    end
  end
end