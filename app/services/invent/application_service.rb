class Invent::ApplicationService < ApplicationService
  protected

  # Возвращает массив статусов с переведенными на русскую локаль ключами.
  def workplace_statuses
    Invent::Workplace.statuses.map { |key, _val| [key, Invent::Workplace.translate_enum(:status, key)] }.to_h
  end

  def item_priorities
    Invent::Item.priorities.map { |key, _val| [key, Invent::Item.translate_enum(:priority, key)] }.to_h
  end

  def prepare_to_***REMOVED***_table(wp)
    wp['short_description'] = wp['workplace_type']['short_description'] if wp['workplace_type']
    wp['fio'] = wp['user_iss'] ? wp['user_iss']['fio_initials'] : 'Ответственный не найден'
    wp['duty'] = wp['user_iss'] ? wp['user_iss']['duty'] : 'Ответственный не найден'
    wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']}, комн. #{wp['iss_reference_room']['name']}"
    wp['status'] = Invent::Workplace.translate_enum(:status, wp['status'])

    wp.delete('iss_reference_site')
    wp.delete('iss_reference_building')
    wp.delete('iss_reference_room')
    wp.delete('user_iss')
    wp.delete('workplace_type')

    wp
  end

  # Подготовить технику для редактирования
  def prepare_to_edit_item(item)
    item['id'] = item['item_id']
    item['property_values_attributes'] = item['property_values']

    item.delete('item_id')
    item.delete('property_values')

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

    value ||= 'нет данных'

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
    return if item['property_values_attributes'].size == type['properties'].size

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
  end
end
