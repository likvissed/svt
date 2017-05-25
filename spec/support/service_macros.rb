module ServiceMacros
  def workplace_attributes
    # Устанавливаем iss_reference_room = nil, так как пользователь с личного кабинета присылает не id, а строковое
    # значение (номер) комнаты.
    tmp = build(
      :workplace_pk,
      :add_items,
      items: %i[pc monitor],
      iss_reference_room: nil,
      workplace_count: workplace_count
    ).as_json(
      include: {
        inv_items: {
          include: :inv_property_values
        }
      },
      methods: :location_room_name
    ).with_indifferent_access

    tmp[:inv_items_attributes] = tmp[:inv_items]
    tmp[:inv_items_attributes].each do |item|
      item[:inv_property_values_attributes] = item[:inv_property_values]

      item.delete(:inv_property_values)
    end

    tmp.delete(:inv_items)

    tmp.with_indifferent_access
  end
end