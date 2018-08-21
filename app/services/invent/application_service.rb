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
      if %w[list list_plus].include?(prop_val['property']['property_type']) && prop_val['property_list_id'].nil? && prop_val['value'].blank?
        prop_val['property_list_id'] = -1
      end

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

  def load_types
    data[:types] = Invent::Type.all.includes(properties: :property_lists).as_json(include: { properties: { include: :property_lists } }).each do |type|
      type['properties'].delete_if { |prop| prop['mandatory'] == false || %w[list list_plus].exclude?(prop['property_type']) }
    end
  end
end
