module Warehouse
  class LocationsController < ApplicationController
    before_action :check_access

    def load_locations
      iss_locations = Invent::LkInvents::InitProperties.new(current_user).load_locations
      new_location = Location.new

      if iss_locations.present?
        render json: { iss_locations: iss_locations, new_location: new_location }
      else
        render json: { full_message: I18n.t('controllers.warehouse/item.load_locations') }, status: 422
      end
    end

    protected

    def check_access
      authorize %i[warehouse location], :ctrl_access?
    end
  end
end
