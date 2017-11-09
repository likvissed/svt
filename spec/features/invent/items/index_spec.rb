require 'feature_helper'

module Invent
  module Items
    feature 'Show all equipment', %q{
      In order to see all equipment that is at work
      As an authenticated user
      I want to be able to go to the index page
    } do
      given(:user) { create :user }
      given(:***REMOVED***_user) { build :***REMOVED***_user }
      given(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
      given!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      given(:item) { workplace.inv_items.first }
      given(:description) do
        item.inv_property_values.as_json(include: %i[inv_property inv_property_list]).map do |prop_val|
          value = if prop_val['inv_property_list']
            prop_val['inv_property_list']['short_description']
          else
            prop_val['value']
          end

          "#{prop_val['inv_property']['short_description']}: #{value}"
        end.join('; ')
      end

      scenario 'Unauthenticated user tries to go to the index page', js: true do
        visit invent_items_path

        expect(page).to have_content 'Вам необходимо войти в систему'
        expect(page).to have_content 'Авторизоваться через Личный Кабинет'
      end

      scenario 'Authenticated user tries to go to the index page', js: true do
        sign_in user
        visit invent_items_path

        expect(page).to have_content 'Выход'
        within '#index_inv_item' do
          within 'table' do
            sleep(1)
            expect(all('tr').count).to eq Invent::InvItem.count + 1
            within 'tbody' do
              expect(all('tr').first).to have_content item.item_id
              expect(all('tr').first).to have_content item.inv_type.short_description
              expect(all('tr').first).to have_content item.item_model
              expect(all('tr').first).to have_content workplace.user_iss.fio
              expect(all('tr').first).to have_content description
            end
          end
        end
      end
    end
  end
end
