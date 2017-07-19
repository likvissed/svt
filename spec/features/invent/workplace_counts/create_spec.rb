require 'feature_helper'

module Invent
  module WorkplaceCounts
    feature 'Create a workplace_count', %q{
      In order to allow responsible users to enter inventory data
      As an authenticated user
      I want to be able to create a workplace_count
    } do
      given(:user) { create :user }

      scenario 'Unauthenticated user tries to create a workplace_count', js: true do
        visit invent_workplace_counts_path

        expect(page).not_to have_button 'Добавить'
        expect(page).to have_content 'Вам необходимо войти в систему'
        expect(page).to have_content 'Авторизоваться через Личный Кабинет'
      end

      context 'Authenticated user' do
        background do
          sign_in user
          visit invent_workplace_counts_path

          click_button 'Добавить'
        end

        context 'with valid main fields' do
          background do
            within '.modal-content' do
              expect(page).to have_content 'Добавить отдел'

              fill_in 'Отдел', with: '***REMOVED***'
              fill_in 'Дата начала ввода данных', with: '31-мая-2017'
              fill_in 'Дата окончания ввода данных', with: '10-июня-2017'
            end
          end

          scenario 'tries to create a new workplace_count (and user with custom phone)', js: true do
            within '.modal-content' do
              find('i.fa.fa-plus-circle.pointer').trigger('click')
              within '.internal-table' do
                expect(page).to have_selector 'tbody'

                fill_in 'workplace_count[users.tn]', with: '***REMOVED***'
              end

              find('i.fa.fa-plus-circle.pointer').trigger('click')
              within '.internal-table' do
                all('input[id="workplace_count_users.tn"]').last.set('15173')
                all('input[id="workplace_count_users.phone"]').last.set('12-34')
              end

              click_button 'Готово'
            end

            expect(page).to have_content 'Отдел ***REMOVED*** добавлен'

            within '.table' do
              expect(page).to have_content '***REMOVED***'
              expect(page).to have_content '***REMOVED***'
              expect(page).to have_content '***REMOVED***'
              expect(page).to have_content '***REMOVED***'
              expect(page).to have_content '12-34'
            end
          end

          scenario 'tries to add the the same responsible several times', js: true do
            within '.modal-content' do
              find('i.fa.fa-plus-circle.pointer').trigger('click')
              within '.internal-table' do
                expect(page).to have_selector 'tbody'

                fill_in 'workplace_count[users.tn]', with: '***REMOVED***'
              end

              find('i.fa.fa-plus-circle.pointer').trigger('click')
              within '.internal-table' do
                all('input[id="workplace_count_users.tn"]').last.set('***REMOVED***')
              end

              click_button 'Готово'
            end

            expect(page).to have_content 'Табельный номер "***REMOVED***" задан несколько раз'
          end

          scenario 'tries to add invalid tn', js: true do
            within '.modal-content' do
              find('i.fa.fa-plus-circle.pointer').trigger('click')
              within '.internal-table' do
                expect(page).to have_selector 'tbody'

                fill_in 'workplace_count[users.tn]', with: '123321'
              end

              click_button 'Готово'
            end

            expect(page)
              .to have_content 'Табельный номер "123321" не существует, проверьте корректность введенного номера'
          end

          context 'when workplace_count exists' do
            let!(:workplace_count) { create :active_workplace_count, users: [user] }

            scenario 'tries to create the same workplace_count', js: true do
              within '.modal-content' do
                find('i.fa.fa-plus-circle.pointer').trigger('click')
                within '.internal-table' do
                  expect(page).to have_selector 'tbody'

                  fill_in 'workplace_count[users.tn]', with: '***REMOVED***'
                end

                click_button 'Готово'
              end

              expect(page).to have_content %q(Отдел '***REMOVED***' уже существует)
            end
          end
        end

        scenario 'tries to create a workplace_count with empty_fields', js: true do
          within '.modal-content' do
            click_button 'Готово'
          end

          expect(page).to have_content 'Отдел не может быть пустым'
          expect(page).to have_content 'Дата начала ввода данных не может быть пустым'
          expect(page).to have_content 'Дата окончания ввода данных не может быть пустым'
          expect(page).to have_content 'Необходимо добавить ответственного'
        end
      end
    end
  end
end
