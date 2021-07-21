module OmniauthMacros
  def login_with_omniauth(user = nil)
    OmniAuth.config.mock_auth[:open_id_***REMOVED***] = OmniAuth::AuthHash.new(
      provider: 'open_id_***REMOVED***',
      uid: '12345',
      info: OmniAuth::AuthHash::InfoHash.new((user || @user).as_json),
      credentials: OmniAuth::AuthHash.new(
        token: 'mock_token',
        secret: 'mock_secret'
      )
    )
  end
end
