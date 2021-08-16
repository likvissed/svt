# Создается событие при смене ответственного на рабочем месте
class Invent::ChangeOwnerWpWorker
  include Sidekiq::Worker

  def perform(workplace_id, data, access_token)
    response = AuthCenter.change_owner_wp(workplace_id, data, access_token)

    return Sidekiq.logger.info "Событие о смене ответственного на РМ создано №#{response['result']}" if response['result'].present?

    Sidekiq.logger.error "Событие о смене ответственного на РМ не создано: wp_id: #{workplace_id}, #{data}".red
  end
end
