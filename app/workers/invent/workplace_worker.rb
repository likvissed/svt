class Invent::WorkplaceWorker
  include Sidekiq::Worker

  def perform(*_args)
    freezing_not_used_workplaces
    freezing_temporary_workplaces
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
    Invent::Workplace.where(status: :temporary, freezing_time: Time.zone.now).update_all(status: :freezed)
  end
end
