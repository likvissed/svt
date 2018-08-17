class LocationsController < ApplicationController
  def rooms_for_building
    render json: IssReferenceBuilding.find(params[:building_id]).iss_reference_rooms
  end
end