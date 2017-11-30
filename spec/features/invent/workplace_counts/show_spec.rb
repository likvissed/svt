require 'feature_helper'

module Invent
  module WorkpalceCounts
    feature 'Show the workplace_count', '
      In order to change data about workplace_count
      As an authenticated user
      I want to be able to load data about selected workpalce_count
    ' do
      given!(:user) { create(:user) }
      given(:***REMOVED***_user) { create(:***REMOVED***_user) }
      given!(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }

      scenario 'Unauthenticated user tries to show a workplace_count', js: true do
        visit invent_workplace_counts_path

        expect(page).not_to have_button 'Добавить'
        expect(page).not_to have_selector 'table'
        expect(page).to have_content 'Вам необходимо войти в систему'
        expect(page).to have_content 'Авторизоваться через Личный Кабинет'
      end

      context 'Authenticated user' do
        background do
          sign_in user
          visit invent_workplace_counts_path
          expect(page).to have_content ***REMOVED***_user.fullname
        end

        scenario 'tries to see data about first workplace_count', js: true do
          within all('table > tbody > tr').first do
            find("a[ng-click='wpCount.openWpCountEditModal(#{workplace_count.workplace_count_id})']").trigger('click')
          end

          within '.modal-content' do
            expect(page).to have_content 'Редактировать отдел'

            within '.modal-body' do
              expect(page)
                .to have_field('workplace_count_division', with: workplace_count.division)

              within all('.internal-table > tbody > tr').first do
                expect(page).to have_field(
                  'workplace_count_users.tn',
                  with: ***REMOVED***_user.tn, disabled: true
                )
                expect(page).to have_field(
                  'workplace_count_users.fullname',
                  with: ***REMOVED***_user.fullname, disabled: true
                )
                expect(page).to have_field(
                  'workplace_count_users.phone',
                  with: ***REMOVED***_user.phone
                )
              end
            end
          end
        end
      end
    end
  end
end
