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
end
