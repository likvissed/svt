module ServiceMacros
  def create_workplace_attributes(valid, **params)
    tmp = if valid
            build(
              :workplace_pk,
              :add_items,
              items: %i[pc monitor],
              iss_reference_room: nil,
              location_room_name: params[:room].name,
              workplace_count: workplace_count
            )
          else
            build(
              :workplace,
              user_iss: nil,
              workplace_specialization: nil,
              iss_reference_room: nil,
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
      },
      methods: :location_room_name
    )

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
      wp.data['location_room_name'] = params[:room].name
      wp.data['id_tn'] = params[:user_iss].id_tn
    else
      # Меняем общие аттрибуты рабочего места
      wp.data['id_tn'] = nil
      wp.data['workplace_specialization'] = nil
      wp.data['location_room_name'] = nil
    end

    # Меняем состав рабочего места
    new_mon = wp.data['items_attributes'].deep_dup.last
    new_mon['id'] = nil
    new_mon['workplace_id'] = nil
    new_mon['item_model'] = 'Monitor model 2'
    new_mon['property_values_attributes'].each do |prop_val|
      prop_val['id'] = nil
      prop_val['item_id'] = nil
    end
    new_mon['status'] = :waiting_take

    wp.data['items_attributes'] << new_mon
    wp.data
  end
end
