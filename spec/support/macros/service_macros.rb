module ServiceMacros
  def create_workplace_attributes(valid, **params)
    tmp = if valid
            build(
              :workplace_pk,
              :add_items,
              items: %i[pc monitor],
              workplace_count: workplace_count
            )
          else
            build(
              :workplace,
              workplace_specialization: nil,
              workplace_count: workplace_count
            )
          end

    # Устанавливаем iss_reference_room = nil (Нельзя устанавливать location_room_id, так как пользователь вручную
    # записывать номер комнаты, а не выбирает из готового списка)
    tmp = tmp.as_json(
      include: {
        items: {
          include: :property_values
        }
      }
    )

    tmp['attachments_attributes'] = []
    tmp['items_attributes'] = tmp['items']
    tmp['items_attributes'].each do |item|
      item['property_values_attributes'] = item['property_values']

      item.delete('property_values')
    end

    tmp.delete('items')
    tmp
  end

  def update_workplace_attributes(valid, current_user, workplace_id, **params)
    wp = Invent::LkInvents::EditWorkplace.new(current_user, workplace_id)
    wp.run

    if valid
      # Меняем общие аттрибуты рабочего места
      wp.data['location_room_id'] = params[:location_room_id]
      wp.data['id_tn'] = params[:employee].first['id']
    else
      # Меняем общие аттрибуты рабочего места
      wp.data['id_tn'] = nil
      wp.data['workplace_specialization'] = nil
      wp.data['location_room_id'] = nil
    end
    wp.data.delete('new_attachment')

    # Меняем состав рабочего места
    new_mon = wp.data['items_attributes'].deep_dup.last
    new_mon['id'] = nil
    new_mon['workplace_id'] = nil
    new_mon['item_model'] = 'Monitor model 2'
    new_mon['property_values_attributes'].each do |prop_val|
      prop_val['id'] = nil
      prop_val['item_id'] = nil
    end

    new_mon['barcode_item_attributes']['id'] = nil
    new_mon['barcode_item_attributes']['codeable_id'] = nil

    wp.data['items_attributes'] << new_mon

    wp.data['items_attributes'].each do |item|
      item.delete('warehouse_orders')
      item.delete('is_open_order')
    end
    wp.data
  end
end
