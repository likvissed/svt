require 'feature_helper'

module Invent
  module Workplaces
    feature 'Show all workplaces', %q{
      In order to see all created workplaces
      As an authenticated user
      I want to be able to go to the index page
    } do
      given(:user) { create :user  }
      given(:workplace_count) { create :active_workplace_count, users: [build(:***REMOVED***_user)] }
      given!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }

      scenario 'Unauthenticated user tries to go to the index page', js: true do
        visit invent_workplaces_path

        expect(page).to have_content 'Вам необходимо войти в систему'
        expect(page).to have_content 'Авторизоваться через Личный Кабинет'
      end

      # scenario 'Authenticatd user tries to go to the index page', js: true do
      #   sign_in user
      #   visit invent_workplaces_path
      #
      #   expect(page).to have_content 'Выход'
      #   expect(page).to have_content workplace.division
      #   expect(page).to have_content workplace.user_iss.fio
      # end
    end
  end
end