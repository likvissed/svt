require 'feature_helper'

module Invent
  module Workplaces
    feature 'Show list of workplaces', %q{
      In order to see all confirm/disapprove workplaces
      As an authenticated user
      I want to be able to go to the index page
    } do
      given(:user) { create :user  }
      given(:workplace_count) { create :active_workplace_count, users: [build(:***REMOVED***_user)] }
      given!(:workplace_pending) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      given!(:workplace_ready) { create :workplace_pk, :add_items, items: %i[allin1], status: :confirmed, workplace_count: workplace_count }

      scenario 'Unauthenticated user tries to go to the list_wp page', js: true do
        visit list_wp_invent_workplaces_path

        expect(page).to have_content 'Вам необходимо войти в систему'
        expect(page).to have_content 'Авторизоваться через Личный Кабинет'
      end

      # scenario 'Authenticatd user tries to go to the index page', js: true do
      #   sign_in user
      #   visit list_wp_invent_workplaces_path
      #
      #   expect(page).to have_content 'Выход'
      #   sleep(5)
      #   within '#index_list_wp' do
      #     puts page.text
      #     expect(all('table > tbody > tr').count).to eq 1
      #     # expect(page).to have_content "ФИО: #{workplace_}"
      #   end
      # end
    end
  end
end