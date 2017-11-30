class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data, :current_user

  # Возвращает массив статусов с переведенными на русскую локаль ключами.
  def workplace_statuses
    Invent::Workplace.statuses.map { |key, _val| [key, Invent::Workplace.translate_enum(:status, key)] }.to_h
  end

  # Разослать сообщение о необходимости обновления сводной таблицы рабочих мест.
  def broadcast_workplaces
    ActionCable.server.broadcast 'workplaces', nil
  end

  # Разослать сообщение о необходимости обновления списка рабочих мест.
  def broadcast_workplace_list
    ActionCable.server.broadcast 'workplace_list', nil
  end

  # Получить данные о составе экземпляра техники в виде тега.
  def property_value_info(prop_val)
    # Флаг показывает, содержится ли значение свойства в поле value (true, если содержится).
    value_flag = false
    if prop_val['property_list']
      value = prop_val['property_list']['short_description']
    elsif !prop_val['value'].empty?
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

  def prepare_to_***REMOVED***_table(wp)
    wp['short_description'] = wp['workplace_type']['short_description'] if wp['workplace_type']
    wp['fio'] = wp['user_iss'] ? wp['user_iss']['fio_initials'] : 'Ответственный не найден'
    wp['duty'] = wp['user_iss'] ? wp['user_iss']['duty'] : 'Ответственный не найден'
    wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп.
#{wp['iss_reference_building']['name']}, комн. #{wp['iss_reference_room']['name']}"
    wp['status'] = Invent::Workplace.translate_enum(:status, wp['status'])

    wp.delete('iss_reference_site')
    wp.delete('iss_reference_building')
    wp.delete('iss_reference_room')
    wp.delete('user_iss')
    wp.delete('workplace_type')

    wp
  end

  # Подготовить технику для удаления
  def prepare_to_edit_item(item)
    item['id'] = item['item_id']
    item['property_values_attributes'] = item['property_values']

    item.delete('item_id')
    item.delete('property_values')

    item['property_values_attributes'].each do |prop_val|
      prop_val['id'] = prop_val['property_value_id']

      # Для пустых значений с типом list и list_plus установить значение = -1 (Это автоматически выберет строчку
      # "Выбрать из списка")
      if %w[list list_plus].include?(prop_val['property']['property_type']) &&
         prop_val['property_list_id'].zero? && prop_val['value'].empty?
        prop_val['property_list_id'] = -1
      end

      prop_val.delete('property')
      prop_val.delete('property_value_id')
    end
  end

  # Получить модель в виде строки
  def get_model(item)
    if item['model']
      "Модель: #{item['model']['item_model']}"
    elsif !item['model'] && !item['item_model'].empty?
      # "<span class='manually-val'>Модель: #{item['item_model']}</span>"
      wrap_problem_string("Модель: #{item['item_model']}")
    else
      'Модель не указана'
    end
  end
end
