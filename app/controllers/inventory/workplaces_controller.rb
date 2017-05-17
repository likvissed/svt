module Inventory
  class WorkplacesController < ApplicationController
    protect_from_forgery except: :create
    load_and_authorize_resource

    def index
      respond_to do |format|
        format.html
        format.json do
          @workplaces = Workplace
                          .includes(:iss_reference_site, :iss_reference_building, :iss_reference_room, :user_iss)
                          .left_outer_joins(:workplace_type)
                          .left_outer_joins(:workplace_count)
                          .left_outer_joins(:inv_items)
                          .select('invent_workplace.*, invent_workplace_count.division, invent_workplace_type
.short_description as wp_type, count(invent_item.item_id) as count')
                          .group(:workplace_id)

          @workplaces = @workplaces.as_json(
            include: %i[iss_reference_site iss_reference_building iss_reference_room user_iss]
          ).each do |wp|
            wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']},
комн. #{wp['iss_reference_room']['name']}"
            wp['responsible'] = wp['user_iss']['fio_initials']
            wp['status'] = Workplace.translate_enum(:status, wp['status'])

            wp.delete('iss_reference_site')
            wp.delete('iss_reference_building')
            wp.delete('iss_reference_room')
            wp.delete('user_iss')
          end

          render json: @workplaces
        end
      end
    end

    def edit
      @wp = SingleWorkplaceService.new(params[:workplace_id])

      respond_to do |format|
        format.html { @workplace = @wp.workplace }
        format.json do
          @wp.transform
          render json: @wp.workplace, status: 200
        end
      end
    end

    private

    def workplace_params
      params.require(:workplace).permit(
        :workplace_count_id,
        :workplace_type_id,
        :id_tn,
        :location,
        :comment,
        :status,
        inv_items_attributes: [
          :id,
          :parent_id,
          :type_id,
          :workplace_id,
          :location,
          :model_name,
          :invent_num,
          :_destroy,
          inv_property_values_attributes: %i[
            id
            property_id
            item_id
            value
            _destroy
          ]
        ]
      )
    end
  end
end
