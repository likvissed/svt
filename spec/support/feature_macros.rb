module FeatureMacros
  def sign_in(user)
    visit new_user_session_path
    expect(page).to have_content 'Авторизоваться через Личный Кабинет'

    login_with_omniauth user
    click_link 'Личный Кабинет'
  end

  private

  def login_with_omniauth(user)
    OmniAuth.config.mock_auth[:open_id_***REMOVED***] = OmniAuth::AuthHash.new(
      provider: 'open_id_***REMOVED***',
      uid: '12345',
      info: OmniAuth::AuthHash::InfoHash.new(user.as_json),
      credentials: OmniAuth::AuthHash.new(
        token: 'mock_token',
        secret: 'mock_secret'
      )
    )
  end
end
