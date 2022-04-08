module AuthCenter
  def authorize_url(state)
    "#{ENV['AUTHORIZATION_URI']}?client_id=#{ENV['CLIENT_ID']}&response_type=code&redirect_uri=#{ENV['REDIRECT_URI']}&state=#{state}"
  end

  def get_token(code)
    RestClient.proxy = ''
    JSON.parse(RestClient::Request.execute(method: :post,
                                           url: ENV['TOKEN_URI'],
                                           payload: {
                                             client_id: ENV['CLIENT_ID'],
                                             client_secret: ENV['CLIENT_SECRET'],
                                             grant_type: 'authorization_code',
                                             redirect_uri: ENV['REDIRECT_URI'],
                                             code: code
                                           }))
  end

  def get_user(access_token)
    JSON.parse(RestClient::Request.execute(method: :post,
                                           url: ENV['USER_INFO_URI'],
                                           headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{access_token}" }))
  end

  def get_new_token(refresh_token)
    JSON.parse(RestClient::Request.execute(method: :post,
                                           url: ENV['TOKEN_URI'],
                                           payload: {
                                             client_id: ENV['CLIENT_ID'],
                                             client_secret: ENV['CLIENT_SECRET'],
                                             grant_type: 'refresh_token',
                                             refresh_token: refresh_token
                                           }))
  end

  def unreg_host(invent_num, access_token)
    data = {}
    data['class'] = 'HOSTREG'
    data['name'] = 'invent_unreg'
    data['severity'] = 'INFO'
    data['subject'] = invent_num
    data['description'] = 'Отправка на склад'

    request = RestClient::Request.new(
      method: :post,
      verify_ssl: false,
      url: ENV['CREATE_EVENT_URI'],
      headers: {
        'Authorization' => "Bearer #{access_token}"
      },
      payload: data
    )

    request.execute { |resp| resp }
  end

  def change_owner_wp(workplace_id, info, access_token)
    data = {}
    data['class'] = 'HOSTREG'
    data['name'] = 'invent_change_owner'
    data['severity'] = 'INFO'
    data['subject'] = workplace_id
    data['data'] = info
    data['description'] = 'Изменение ответственного на РМ'

    request = RestClient::Request.new(
      method: :post,
      verify_ssl: false,
      url: ENV['CREATE_EVENT_URI'],
      headers: {
        'Authorization' => "Bearer #{access_token}"
      },
      payload: data
    )

    request.execute { |resp| resp }
  end
end
