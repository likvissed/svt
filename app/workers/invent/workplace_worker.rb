class Invent::WorkplaceWorker
  include Sidekiq::Worker

  def perform(*_args)
    freezing_not_used_workplaces
    freezing_temporary_workplaces
    clear_cache
  end

  protected

  # Заморозить РМ, у которых отсутствует ответственный или список привязанной техники
  def freezing_not_used_workplaces
    ids = Invent::Workplace.where(status: :confirmed).includes(:user_iss, :workplace_count, :items).find_each.map do |wp|
      next if wp.user_iss && wp.user_iss.dept.to_i == wp.division.to_i && wp.items.size.positive?

      wp.workplace_id
    end.compact

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
