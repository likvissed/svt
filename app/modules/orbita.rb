# Запросы в ***REMOVED***-center
module Orbita
  # Добавление события
  def self.add_event(id, user_id_tn, type, params = nil, files = nil)
    data = {}
    data['integration_id'] = id
    data['id_tn'] = user_id_tn
    data['event_type'] = type
    data['payload'] = params if params.present?
    data['files'] = files if files.present?

    Rails.logger.info "data #{data.inspect}".cyan

    request = RestClient::Request.new(
      method: :post,
      verify_ssl: false,
      url: ENV['ORBITA_EVENTS_URI'],
      headers: {
        'Content-Type' => 'application/json'
      },
      payload: data.to_json
    )

    # Rails.logger.info "Response code #{request.inspect}".green
    # true

    response = request.execute { |resp| resp }
    Rails.logger.info "Response code #{response.code}".green
    Rails.logger.info "Response #{JSON.parse(response)}".red

    case response.code
    when 200
      # if JSON.parse(response)['message'] == 'событие обработано'
      true
    else
      false
    end
  end
end
