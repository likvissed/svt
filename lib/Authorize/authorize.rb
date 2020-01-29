class Authorize
  class << self
    def get_url(state)
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
                                             url: 'https://auth-center.***REMOVED***.ru/api/module/main/login_info',
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
  end
end
