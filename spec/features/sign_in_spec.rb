require 'feature_helper'

feature 'User sign in', '
  In order to use application
  as an user
  I want to be able to sign in
' do

  given(:user) { create(:user) }
  given(:unregistered_user) { attributes_for(:user) }

  scenario 'Registered user tries to sign in' do
    sign_in user

    expect(page).to have_selector 'body#svt_welcome'
    expect(page).to have_content 'Выход'
  end

  scenario 'Unregistered user tries to sign in', js: true do
    sign_in unregistered_user

    expect(page).to have_selector 'body#svt_sign_in'
    expect(page).to have_content 'Доступ запрещен'
  end
end
