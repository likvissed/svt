class CreateEventMailer < ApplicationMailer
  def send_email(msg, content, data)
    mail(to: ENV['EMAILS_HOSTREG'], subject: "Инвентаризация: #{msg} #{data}", body: content)
  end
end
