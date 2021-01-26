module Audit
  # Получить данные на сервере smssvr64
  # mac - MAC-адрес компьютера
  def self.configuration_data(mac)
    request = RestClient::Request.new(
      method: :get,
      verify_ssl: false,
      proxy: nil,
      url: "#{ENV['AUDIT_CONFIG_URI']}?mac=#{mac}"
    )
    response = request.execute { |resp| resp }

    case response.code
    when 200
      return JSON.parse(response)
    else
      return []
    end
  end
end
