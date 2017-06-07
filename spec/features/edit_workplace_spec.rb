require 'feature_helper'

feature 'Edit workplace', %q{
  In order to check the workplace configuration
  as an user with admin role
  I want to be able to see the workplace configuration
} do

  given(:user) { create(:user) }
  given!(:workplace_count) { create(:active_workplace_count, :default_user) }
  given!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }

  scenario 'Unauthenticated user tries to check configuration', js: true do
    visit edit_inventory_workplace_path(workplace)

    expect(page).to have_selector 'body#svt_sign_in'
    expect(page).to have_content 'Вам необходимо войти в систему'
  end

  # scenario 'Authenticated user tries to check configuration', js: true do
  #   sign_in user
  #   visit edit_inventory_workplace_path(workplace)
  #
  #   expect(page).to have_content 'Данные о рабочем месте'
  #   expect(page).to have_content workplace.workplace_type_id
  #
  #   expect(page).to have_content 'Расположение рабочего места'
  #   expect(page).to have_content workplace.location_site_id
  #
  #   expect(page).to have_content 'Состав рабочего места'
  #   within '#wp_consist' do
  #     expect(page).to have_content('li', count: workplace.inv_items.count)
  #   end
  # end

end
