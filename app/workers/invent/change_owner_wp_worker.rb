# Создается событие при смене ответственного на рабочем месте
class Invent::ChangeOwnerWpWorker
  include Sidekiq::Worker

  def perform(workplace_id, data, access_token)
    response = AuthCenter.change_owner_wp(workplace_id, data, access_token)

    msg = 'Событие о смене ответственного на РМ'
    case response.code
    when 200
      Sidekiq.logger.info "#{msg} создано № #{JSON.parse(response)['result']}"
    else
      Sidekiq.logger.error "<#{response.code}> #{msg} НЕ создано wp_id: #{workplace_id}, #{data}"

      CreateEventMailer.send_email("#{msg} НЕ создано", response, "#{workplace_id}, #{data}").deliver
    end
  end
end
