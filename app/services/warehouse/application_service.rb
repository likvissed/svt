class Warehouse::ApplicationService < ApplicationService;
  protected

  # Подготовить технику для редактирования
  def prepare_to_edit_item(item)
    item['property_values_attributes'] = item['property_values']

    item.delete('property_values')
    item.delete('inv_type')

    item['property_values_attributes'].each do |prop_val|
      prop_val['id'] = prop_val['warehouse_property_value_id']

      prop_val.delete('property') if prop_val['property'].present?
      prop_val.delete('warehouse_property_value_id')
    end
  end

  def create_or_get_room_id
    # Если команта введена вручную
    if @item_params['location_attributes']['room_id'] == -1
      room = IssReferenceRoom.find_by(name: @item_params['location_attributes']['name'], building_id: @item_params['location_attributes']['building_id'])
      category_id = if room.present?
                      room.security_category_id
                    else
                      RoomSecurityCategory.missing_category.id
                    end

      room = Invent::Room.new(@item_params['location_attributes']['name'], @item_params['location_attributes']['building_id'], category_id)

      @item_params['location_attributes']['room_id'] = room.data.room_id if room.run
    end
    @item_params['location_attributes'].delete 'name'
  end
end
