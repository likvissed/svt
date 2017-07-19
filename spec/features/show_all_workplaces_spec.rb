require 'feature_helper'

feature 'Show all workplaces', %q{
  In order to see all workplaces
  as an user
  I want to be able to load workplaces page
} do

  given(:user) { create(:user) }

  scenario 'Authenticated user tries to see all workplaces', js: true do
    sign_in user
    visit invent_workplaces_path

    expect(page).to have_css('#index_workplace')
  end

  scenario 'Unauthenticated user try to show all workplaces', js: true do
    visit invent_workplaces_path

    expect(page).to have_selector 'body#svt_sign_in'
    expect(page).to have_content('Вам необходимо войти в систему')
  end
end
