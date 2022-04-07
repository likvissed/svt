class UnregistrationWorker
  include Sidekiq::Worker

  def perform(invent_num, access_token)
    response = AuthCenter.unreg_host(invent_num, access_token)

    case response.code
    when 200
      Sidekiq.logger.info "Событие на разрегистрацию техники создано № #{JSON.parse(response)['result']}"
    else
      Sidekiq.logger.error "Событие на разрегистрацию техники НЕ создано для инв.№ : #{invent_num}"
      Sidekiq.logger.error "code #{response.code}; #{response}"

      UnregHostMailer.send_email(response, invent_num).deliver
    end
  end
end
