class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data

  # Возвращает объект @current_user
  def current_user
    @current_user
  end

  # Возвращает массив статусов с переведенными на русскую локаль ключами.
  def statuses
    Inventory::Workplace.statuses.map{ |key, val| [key, Inventory::Workplace.translate_enum(:status, key)] }.to_h
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
end