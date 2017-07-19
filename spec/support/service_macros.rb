module ServiceMacros
  def create_workplace_attributes(**params)
    # Устанавливаем iss_reference_room = nil (Нельзя устанавливать location_room_id, так как пользователь вручную
    # записывать номер комнаты, а не выбирает из готового списка)
    tmp = build(
      :workplace_pk,
      :add_items,
      items: %i[pc monitor],
      iss_reference_room: nil,
      location_room_name: params[:room].name,
      workplace_count: workplace_count,
    ).as_json(
      include: {
        inv_items: {
          include: :inv_property_values
        }
      },
      methods: :location_room_name
    ).deep_symbolize_keys

    tmp[:inv_items_attributes] = tmp[:inv_items]
    tmp[:inv_items_attributes].each do |item|
      item[:inv_property_values_attributes] = item[:inv_property_values]

      item.delete(:inv_property_values)
    end

    tmp.delete(:inv_items)

    tmp.deep_symbolize_keys
  end

  def update_workplace_attributes(current_user, workplace_id, **params)
    wp = Invent::LkInvents::EditWorkplace.new(current_user, workplace_id)
    wp.run
    # Меняем общие аттрибуты рабочего места
    wp.data['location_room_name'] = params[:room].name
    wp.data['id_tn'] = params[:user_iss].id_tn

    # Меняем состав рабочего места
    new_mon = wp.data['inv_items_attributes'].deep_dup.last
    new_mon['id'] = nil
    new_mon['item_model'] = 'Monitor model 2'
    new_mon['inv_property_values_attributes'].each { |prop_val| prop_val['id'] = nil }

    wp.data['inv_items_attributes'] << new_mon

    wp.data
  end
end