class Invent::WorkplaceWorker
  include Sidekiq::Worker

  def perform(*args)
    ids = Invent::Workplace.where(status: :confirmed).includes(:user_iss, :workplace_count, :items).find_each.map do |wp|
      next if wp.user_iss && wp.user_iss.dept == wp.division && wp.items.size.positive?

      wp.workplace_id
    end.compact

    Invent::Workplace.where(workplace_id: ids).update_all(status: :freezed)
  end
end
