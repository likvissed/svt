require 'feature_helper'

module Inventory
  module WorkplaceCounts
    feature 'Show all workplace counts', %q{
      In order to see all divisions and responsible users
      As an authenticated user
      I want to be able to go to the index page
    } do
      given(:user) { create(:user) }
      given!(:workplace_count) { create(:active_workplace_count) }

      scenario 'Unauthenticated user tries to go to the index page', js: true do
        visit inventory_workplace_counts_path

        expect(page).to have_content 'Вам необходимо войти в систему'
        expect(page).to have_content 'Авторизоваться через Личный Кабинет'
      end

      scenario 'Authenticated user tries to go to the index page', js: true do
        sign_in user
        visit inventory_workplace_counts_path

        expect(page).to have_content 'Выход'
        expect(page).to have_content workplace_count.division

        workplace_count.users.each do |user|
          expect(page).to have_content user['fio']
        end
      end
    end
  end
end