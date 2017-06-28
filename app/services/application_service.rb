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
end