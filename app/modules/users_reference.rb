# Запросы к БД НСИ
module UsersReference
  # Получение нового токена (ключ: 'token_hr')
  def self.new_token_hr
    RestClient.proxy = ''
    token = JSON.parse(RestClient::Request.execute(method: :post,
                                                   url: ENV['USERS_REFERENCE_URI_LOGIN'],
                                                   headers: {
                                                     'X-Auth-Username' => ENV['NAME_USER_HR'],
                                                     'X-Auth-Password' => ENV['PASSWORD_USER_HR']
                                                   }))

    Rails.cache.write('token_hr', token['token'])
  end

  # Поиск данных о пользователях
  def self.user_where(params_search)
    token = Rails.cache.read('token_hr')

    RestClient.proxy = ''
    request = RestClient::Request.new(
      method: :get,
      url: "#{ENV['USERS_REFERENCE_URI_SEARCH']}=#{params_search}",
      headers: {
        'X-Auth-Token' => token
      }
    )
    response = request.execute { |resp| resp }

    case response.code
    when 200
      JSON.parse(response)['data']
    when 500
      nil
    end
  end

  # Проверка существования валидного токена и поиск данных с параметрами - params
  def self.info_users(params)
    (0..1).each do |_|
      new_token_hr if Rails.cache.read('token_hr').blank?
      response = user_where(params)

      return response if response

      Rails.cache.delete('token_hr')
    end
    []
  end
end
