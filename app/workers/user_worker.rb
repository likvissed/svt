class UserWorker
  include Sidekiq::Worker

  def perform(*_args)
    delete_fired_users
  end

  protected

  # Удалить пользователя, который больше не числится сотрудником
  def delete_fired_users
    ids = ids_fired_users

    if ids.any?
      users = User.where(id: ids)

      Sidekiq.logger.info "delete_fired_users: #{users.pluck(:fullname)}"
      users.destroy_all if ids.any?
    end
  end

  def ids_fired_users
    users = User.includes(:workplace_counts).where.not(fullname: 'AuditBot')
    array_id_tn = users.map(&:id_tn).compact.uniq.join(',')
    employees = UsersReference.info_users("id=in=(#{array_id_tn})").map { |employee| employee.slice('id') }

    users.find_each.map do |user|
      # Найти пользователя в базе сотрудников
      match = employees.find { |value| value['id'] == user.id_tn }

      next if match.present?

      user.id
    end.compact
  end
end
