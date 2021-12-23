# Запросы в ssd
module SSD
  # Отправка файла на подпись
  def self.send_for_signature(request_id, files, login_starter, login_signer, barcode)
    data = {}
    data['files'] = files
    data['login_starter'] = login_starter
    data['login_signer'] = login_signer
    data['barcode'] = barcode
    data['callback_url'] = "https://#{ENV['APP_HOSTNAME']}.***REMOVED***.ru/api/v3/warehouse/requests/answer_from_owner/#{request_id}"

    request = RestClient::Request.new(
      method: :post,
      verify_ssl: false,
      url: ENV['SSD_FOR_SIGNATURE_URI'],
      headers: {
        'Content-Type' => 'multipart/form-data'
      },
      payload: data
    )

    response = request.execute { |resp| resp }

    case response.code
    when 200
      if JSON.parse(response)['result'] == 1
        JSON.parse(response)['message']
      else
        raise "SSD -1: #{JSON.parse(response)['message']}"
      end
    else
      raise "SSD response: #{response.code}: #{response}"
    end
  end
end
