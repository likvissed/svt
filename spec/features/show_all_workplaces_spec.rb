require 'feature_helper'

feature 'Show all workplaces', %q{
  In order to see all workplaces
  as an user
  I want to be able to load workplaces page
} do

  given(:user) { create(:user) }

  scenario 'Registered user tries to see all workplaces' do
    sign_in user
    visit inventory_workplaces_path

    expect(page).to have_css('#index_workplace')
  end

  scenario 'Unregistered user try to show all workplaces', js: true do
    visit inventory_workplaces_path

    expect(page).to have_selector 'body#svt_sign_in'
    expect(page).to have_content('Вам необходимо войти в систему')
  end
end
