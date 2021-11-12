# Запросы в ***REMOVED***-center
module Orbita
  # Добавление события
  def self.add_event(id, user_id_tn, type, params = nil, files = nil)
    (0..1).each do |_|
      token if Rails.cache.read('token_***REMOVED***').blank?

      data = {}
      data['integration_id'] = id
      data['id_tn'] = user_id_tn
      data['event_type'] = type
      data['payload'] = params if params.present?
      data['files'] = files if files.present?

      request = RestClient::Request.new(
        method: :post,
        verify_ssl: false,
        url: ENV['ORBITA_EVENTS_URI'],
        headers: {
          'Authorization' => "Bearer #{Rails.cache.read('token_***REMOVED***')}",
          'Accept' => 'application/json'
        },
        payload: data
      )
      # Rails.logger.info "data #{data}".cyan

      response = request.execute { |resp| resp }

      case response.code
      when 200
        # return true if JSON.parse(response)['message'] == 'Событие обработано'
        break
        # true
      else
        Rails.logger.info "***REMOVED*** response: #{response.code}: #{response}".red
        Rails.cache.delete('token_***REMOVED***')
        false
      end
    end
  end

  def self.token
    request = RestClient::Request.new(
      method: :post,
      verify_ssl: false,
      url: ENV['ORBITA_TOKEN_URI'],
      payload: {
        client_id: ENV['ORBITA_CLIENT_ID'],
        client_secret: ENV['ORBITA_SECRET'],
        grant_type: 'client_credentials'
      }
    )

    response = request.execute { |resp| resp }

    case response.code
    when 200
      Rails.cache.write('token_***REMOVED***', JSON.parse(response)['access_token'])
      true
    else
      false
    end
  end
end
