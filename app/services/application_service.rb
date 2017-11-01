class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data, :current_user

  # Возвращает массив статусов с переведенными на русскую локаль ключами.
  def statuses
    Invent::Workplace.statuses.map { |key, _val| [key, Invent::Workplace.translate_enum(:status, key)] }.to_h
  end

  # Возвращает строку, содержащую расположение РМ.
  def wp_location_string(wp)
    "Пл. '#{wp['iss_reference_site']['name']}', корп. '#{wp['iss_reference_building']['name']}', комн. '#{wp['iss_reference_room']['name']}'"
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
    if prop_val['inv_property_list']
      value = prop_val['inv_property_list']['short_description']
    elsif !prop_val['value'].empty?
      value = prop_val['value']
      value_flag = true
    end

    value ||= 'нет данных'

    result = "#{prop_val['inv_property']['short_description']}: #{value}"

    if prop_val['inv_property']['property_type'] == 'list_plus' && value_flag
      "<span class='manually-val'>#{result}</span>"
    else
      result
    end
  end
end
