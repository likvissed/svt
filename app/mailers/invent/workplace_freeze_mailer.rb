class Invent::WorkplaceFreezeMailer < ApplicationMailer
  def send_email(not_used, decree, was_temporary)
    @not_used = not_used
    @decree = decree
    @was_temporary = was_temporary

    mail(to: ENV['EMAILS_FREEZE_WP_OFFICE'], subject: 'Инвентаризация: Заморозка рабочих мест (Оргтехника)')
  end

  def send_email_print(not_used, decree, was_temporary)
    @not_used = not_used
    @decree = decree
    @was_temporary = was_temporary

    mail(to: ENV['EMAILS_FREEZE_WP_PRINT'], subject: 'Инвентаризация: Заморозка рабочих мест (Печатная техника)', template_name: 'send_email')
  end
end
