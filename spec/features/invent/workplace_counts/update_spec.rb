require 'feature_helper'

module Invent
  module WorkplaceCounts
    feature 'Update a workplace_count', '
      In order to allow responsible users to enter inventory data
      As an authenticated user
      I want to be able to update a workplace_count
    ' do
      given(:user) { create(:user) }
      given(:***REMOVED***_user) { create(:***REMOVED***_user) }
      given!(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }

      background do
        sign_in user
        visit invent_workplace_counts_path

        expect(page).to have_content ***REMOVED***_user.fullname
        within all('table > tbody > tr').first do
          find("a[ng-click='wpCount.openWpCountEditModal(#{workplace_count.workplace_count_id})']").trigger('click')
        end

        within '.modal-content' do
          expect(page).to have_content 'Редактировать отдел'
        end
      end

      scenario 'tries to update main fields with valid fields', js: true do
        within '.modal-content' do
          fill_in 'Отдел', with: '***REMOVED***'
          fill_in 'Дата начала ввода данных', with: '10-июня-2017'
          fill_in 'Дата окончания ввода данных', with: '20-июня-2017'
        end
        click_button 'Готово'

        expect(page).to have_content 'Данные одела ***REMOVED*** обновлены'
        within '.table' do
          expect(page).not_to have_content workplace_count.division
          expect(page).to have_content '***REMOVED***'
        end
      end

      scenario 'tries to update main fields with invalid fields', js: true do
        within '.modal-content' do
          fill_in 'Отдел', with: ''
          fill_in 'Дата начала ввода данных', with: ''
          fill_in 'Дата окончания ввода данных', with: ''
        end
        click_button 'Готово'

        expect(page).to have_content 'Отдел не может быть пустым'
        expect(page).to have_content 'Дата начала ввода данных не может быть пустым'
        expect(page).to have_content 'Дата окончания ввода данных не может быть пустым'
      end

      context 'when works with responsibles' do
        scenario 'tries to add valid responsible with custom phone', js: true do
          within '.modal-content' do
            find('i.fa.fa-plus-circle.pointer').trigger('click')

            within '.internal-table' do
              expect(page).to have_selector 'tbody'

              all('input[id="workplace_count_users.tn"]').last.set('15173')
              all('input[id="workplace_count_users.phone"]').last.set('12-34')
            end

            click_button 'Готово'
          end

          expect(page).to have_content 'Данные одела ***REMOVED*** обновлены'
          within '.table' do
            expect(page).to have_content '***REMOVED***'
            expect(page).to have_content '***REMOVED***'
            expect(page).to have_content '***REMOVED***'
            expect(page).to have_content '***REMOVED***'
            expect(page).to have_content '12-34'
          end
        end

        scenario 'tries to add invalid responsible', js: true do
          within '.modal-content' do
            find('i.fa.fa-plus-circle.pointer').trigger('click')

            within '.internal-table' do
              expect(page).to have_selector 'tbody'

              all('input[id="workplace_count_users.tn"]').last.set('123321')
            end

            click_button 'Готово'
          end

          expect(page)
            .to have_content 'Табельный номер "123321" не существует, проверьте корректность введенного номера'
        end

        scenario 'tries to remove old and add a new responsible', js: true do
          within '.modal-content' do
            # Удалить старого ответственного
            within '.internal-table' do
              find('i.fa.fa-minus-circle.fa-lg.pointer').trigger('click')
            end

            find('i.fa.fa-plus-circle.pointer').trigger('click')

            within '.internal-table' do
              expect(page).to have_selector 'tbody'

              all('input[id="workplace_count_users.tn"]').last.set('15173')
            end

            click_button 'Готово'
          end

          expect(page).to have_content 'Данные одела ***REMOVED*** обновлены'
          within '.table' do
            expect(page).to have_content '***REMOVED***'
            expect(page).not_to have_content '***REMOVED***'
            expect(page).to have_content '***REMOVED***'
            expect(page).to have_content '***REMOVED***'
          end
        end

        scenario 'tries to remove and add the same responsible', js: true do
          within '.modal-content' do
            # Удалить старого ответственного
            within '.internal-table' do
              find('i.fa.fa-minus-circle.fa-lg.pointer').trigger('click')
            end

            find('i.fa.fa-plus-circle.pointer').trigger('click')

            within '.internal-table' do
              expect(page).to have_selector 'tbody'

              all('input[id="workplace_count_users.tn"]').last.set('***REMOVED***')
            end

            click_button 'Готово'
          end

          expect(page).to have_content 'Ответственный для данного отдела с табельным ***REMOVED*** уже существует (либо вы его задали несколько раз)'
        end

        scenario 'tries to add responsible which already exists for current workplace_count', js: true do
          within '.modal-content' do
            find('i.fa.fa-plus-circle.pointer').trigger('click')

            within '.internal-table' do
              expect(page).to have_selector 'tbody'

              all('input[id="workplace_count_users.tn"]').last.set('***REMOVED***')
            end

            click_button 'Готово'
          end

          expect(page).to have_content 'Ответственный для данного отдела с табельным ***REMOVED*** уже существует (либо вы его задали несколько раз)'
        end

        scenario 'tries to add a new responsible (the same) several times', js: true do
          within '.modal-content' do
            2.times do
              find('i.fa.fa-plus-circle.pointer').trigger('click')

              within '.internal-table' do
                expect(page).to have_selector 'tbody'

                all('input[id="workplace_count_users.tn"]').last.set('***REMOVED***')
              end
            end

            click_button 'Готово'
          end

          expect(page).to have_content 'Ответственный для данного отдела с табельным ***REMOVED*** уже существует (либо вы его задали несколько раз)'
        end
      end
    end
  end
end
