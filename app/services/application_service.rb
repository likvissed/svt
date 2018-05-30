class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data, :current_user, :error

  def initialize(*args)
    @data = {}
    @error = {}
  end

  # Разослать сообщение о необходимости обновления сводной таблицы рабочих мест.
  def broadcast_workplaces
    ActionCable.server.broadcast 'workplaces', nil
  end

  def broadcast_archive_orders
    ActionCable.server.broadcast 'archive_orders', nil
  end

  def broadcast_users
    ActionCable.server.broadcast 'users', nil
  end

  def load_roles
    data[:roles] = Role.all
  end
end
