require_relative './omniauth_macros'

module FeatureMacros
  include OmniauthMacros

  def sign_in(user)
    visit new_user_session_path
    expect(page).to have_content 'Авторизоваться через Личный Кабинет'

    login_with_omniauth user
    click_link 'Личный Кабинет'
  end
end
