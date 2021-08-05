class Invent::ApplicationService < ApplicationService
  protected

  # Возвращает массив статусов с переведенными на русскую локаль ключами.
  def workplace_statuses
    Invent::Workplace.statuses.map { |key, _val| [key, Invent::Workplace.translate_enum(:status, key)] }.to_h
  end

  def item_priorities
    Invent::Item.priorities.map { |key, _val| [key, Invent::Item.translate_enum(:priority, key)] }.to_h
  end

  def prepare_to_***REMOVED***_table(wp, employee)
    wp['short_description'] = wp['workplace_type']['short_description'] if wp['workplace_type']

    user_wp = employee.find { |emp| emp['id'] == wp['id_tn'] }
    wp['fio'] = user_wp ? "#{user_wp['lastName'].capitalize} #{user_wp['firstName'][0]}.#{user_wp['middleName'][0]}." : 'Ответственный не найден'
    wp['duty'] = user_wp ? user_wp['professionForDocuments'].downcase : 'Ответственный не найден'

    wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']}, комн. #{wp['iss_reference_room']['name']}"
    wp['status'] = Invent::Workplace.translate_enum(:status, wp['status'])

    wp.delete('iss_reference_site')
    wp.delete('iss_reference_building')
    wp.delete('iss_reference_room')
    wp.delete('workplace_type')

    wp
  end

  # Подготовить технику для редактирования
  def prepare_to_edit_item(item)
    item['id'] = item['item_id']
    item['is_open_order'] = item['warehouse_orders'].any? { |order| order['status'] == 'processing' } if item['warehouse_orders'].present?
    item['property_values_attributes'] = item['property_values']
    item['barcode_item_attributes'] = item['barcode_item']

    item.delete('item_id')
    item.delete('property_values')
    item.delete('barcode_item')

    item['property_values_attributes'].each do |prop_val|
      prop_val['id'] = prop_val['property_value_id']

      # Для пустых значений с типом list и list_plus установить значение = -1 (Это автоматически выберет строчку
      # "Выбрать из списка")
      prop_val['property_list_id'] = -1 if Invent::Property::LIST_PROPS.include?(prop_val['property']['property_type']) && prop_val['property_list_id'].nil? && prop_val['value'].blank?

      prop_val.delete('property')
      prop_val.delete('property_value_id')
    end
  end

  # Получить данные о составе экземпляра техники в виде тега.
  def property_value_info(prop_val)
    # Флаг показывает, содержится ли значение свойства в поле value (true, если содержится).
    value_flag = false
    if prop_val['property_list']
      value = prop_val['property_list']['short_description']
    elsif prop_val['value'].present?
      value = prop_val['value']
      value_flag = true
    end

    value = if value.blank?
              'нет данных'
            elsif %w[date replacement_date].include? prop_val['property']['name']
              Time.zone.parse(value).strftime('%d.%m.%Y')
            else
              value
            end

    result = "#{prop_val['property']['short_description']}: #{value}"

    if prop_val['property']['property_type'] == 'list_plus' && value_flag
      "<span class='manually-val'>#{result}</span>"
    else
      result
    end
  end

  # Создать значения для свойств типа list и list_plus (если значения отсутствуют)
  def generate_property_values_for_item(item)
    type = data[:prop_data][:eq_types].find { |t| t['type_id'] == item['type_id'] }

    type['properties'].each do |prop|
      # Ищем отсутствующие свойства
      next if item['property_values_attributes'].find { |prop_val| prop_val['property_id'] == prop['property_id'] }

      new_prop_val = Invent::PropertyValue.new
      if Invent::Property::LIST_PROPS.include?(prop['property_type'])
        prop['property_lists'].each do |prop_list|
          new_prop_val['property_list_id'] = prop_list['property_list_id'] if prop_list['model_property_lists'].find { |m_prop_list| m_prop_list['model_id'] == item['model_id'] && m_prop_list['property_id'] == prop_list['property_id'] }
        end

        new_prop_val['property_list_id'] ||= -1
      end

      new_prop_val['property_id'] = prop['property_id']
      item['property_values_attributes'] << new_prop_val
    end
    order_property_values(item)
  end

  # Сортирует значения в property_values_attributes в соответствии с Property.order(:property_order)
  def order_property_values(item)
    type = data[:prop_data][:eq_types].find { |t| t['type_id'] == item['type_id'] }

    new_property_values = []
    type['properties'].each do |prop|
      new_property_values.concat(item['property_values_attributes'].find_all { |prop_val| prop_val['property_id'] == prop['property_id'] })
    end

    item['property_values_attributes'] = new_property_values
  end

  # Удалить property_value, которые включены для назначения штрих-кода (Property.assign_barcode = true)
  # при создании/обновлении РМ (и обновлении техники) - чтобы не создавалась пустая запись этих свойств
  def delete_blank_and_assign_barcode_prop_value(property_values_attr)
    property_with_assign_barcode = Invent::Property.where(assign_barcode: true).pluck(:property_id)

    property_values_attr.delete_if do |prop_val|
      property_with_assign_barcode.include?(prop_val['property_id']) && prop_val['value'].blank?
    end

    property_values_attr
  end
end
