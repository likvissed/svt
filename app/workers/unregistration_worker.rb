class UnregistrationWorker
  include Sidekiq::Worker

  def perform(invent_num, access_token)
    response = AuthCenter.unreg_host(invent_num, access_token)

    return Sidekiq.logger.info "Событие на разрегистрацию техники создано №#{response['result']}" if response['result'].present?

    Sidekiq.logger.error "Событие на разрегистрацию техники не создано для инв.№ : #{invent_num}"
    UnregHostMailer.send_email(response, invent_num).deliver
  end
end
