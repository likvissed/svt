class UnregHostMailer < ApplicationMailer
  def send_email(content, invent_num)
    mail(to: ENV['EMAILS_HOSTREG'], subject: "Инвентаризация: Событие не создано для инв.№ #{invent_num}", body: content)
  end
end
