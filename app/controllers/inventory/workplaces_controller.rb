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
      @workplace = Workplace
                     .includes(:iss_reference_room)
                     .find(params[:workplace_id])

      respond_to do |format|
        format.html
        format.json do
          unless @workplace
            render json: { full_message: 'Рабочее место не найдено.' }, status: 404
            return
          end

          @workplace = @workplace.as_json(
            include: {
              iss_reference_room: {},
              inv_items: {
                include: :inv_property_values
              }
            }
          )

          # Преобразование объекта.
          @workplace['location_room_name'] = @workplace['iss_reference_room']['name']
          @workplace['inv_items_attributes'] = @workplace['inv_items']
          @workplace.delete('inv_items')
          @workplace.delete('iss_reference_room')
          @workplace.delete('location_room_id')

          @workplace['inv_items_attributes'].each do |item|
            item['id'] = item['item_id']
            item['inv_property_values_attributes'] = item['inv_property_values']
            item.delete('item_id')
            item.delete('inv_property_values')

            item['inv_property_values_attributes'].each do |prop_val|
              prop_val['id'] = prop_val['property_value_id']
              prop_val.delete('property_value_id')
            end
          end

          render json: @workplace, status: 200
        end
      end
    end

    private

    def workplace
      @workplace = Workplace.find(params[:workplace_id]) unless @workplace
    end

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
