class StatisticsOrderMailer < ApplicationMailer
  def report_email(file, month)
    attachments[Time.zone.now.strftime('%d-%m-%Y.xlsx')] = {
      mime_type: 'Mime::XLSX',
      content: file
    }

    mail(
      to: ENV['EMAILS_STATISTICS'],
      subject: "\"Инвентаризация\": Статистика за #{month.downcase}",
      body: 'В прикрепленном файле содержится статистика по системным блокам и моноблокам'
    )
  end
end
