class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data, :current_user, :error

  # Разослать сообщение о необходимости обновления сводной таблицы рабочих мест.
  def broadcast_workplaces
    ActionCable.server.broadcast 'workplaces', nil
  end

  def broadcast_archive_orders
    ActionCable.server.broadcast 'archive_orders', nil
  end
end
