# Создается событие при переносе техники на склад
class UnregistrationWorker
  include Sidekiq::Worker

  def perform(invent_num, access_token)
    response = AuthCenter.unreg_host(invent_num, access_token)

    msg = 'Событие на разрегистрацию техники'
    case response.code
    when 200
      Sidekiq.logger.info "#{msg} создано № #{JSON.parse(response)['result']}"
    else
      Sidekiq.logger.error "<#{response.code}> #{msg} НЕ создано для инв.№: #{invent_num}"

      CreateEventMailer.send_email("#{msg} НЕ создано", response, invent_num).deliver
    end
  end
end
