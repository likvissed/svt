class Invent::WorkplaceWorker
  include Sidekiq::Worker

  def perform(*_args)
    freezing_not_used_workplaces
    freezing_temporary_workplaces
    clear_cache
  end

  protected

  def ids_workplace
    workplaces = Invent::Workplace.where(status: :confirmed).includes(:workplace_count, :items)
    array_id_tn = workplaces.map(&:id_tn).compact.uniq.join(',')
    employees = UsersReference.info_users("id=in=(#{array_id_tn})").map { |employee| employee.slice('id', 'departmentForAccounting') }

    workplaces.find_each.map do |wp|
      # Совпадает ли отдел с отделом пользователя на этом РМ
      match = employees.find { |value| value['departmentForAccounting'] == wp.division.to_i && value['id'] == wp.id_tn }

      next if match.present? && wp.items.size.positive?

      wp.workplace_id
    end.compact
  end

  # Заморозить РМ, у которых отсутствует ответственный или список привязанной техники
  def freezing_not_used_workplaces
    ids = ids_workplace

    Invent::Workplace.where(workplace_id: ids).update_all(status: :freezed) if ids.any?
  end

  # Заморозить временные РМ, у которых прошел срок работы.
  def freezing_temporary_workplaces
    Invent::Workplace.where(status: 'temporary').where('freezing_time <= ?', Time.zone.now).update_all(status: :freezed)
  end

  # Очистить кэш, для того, чтобы обновлённые статусы отображались у пользователей
  def clear_cache
    Rails.cache.clear
  end
end
