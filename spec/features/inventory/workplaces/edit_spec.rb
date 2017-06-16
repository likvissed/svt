require 'feature_helper'

module Inventory
  module Workplaces
    feature 'Edit workplace', %q{
      In order to edit the workplace configuration
      an an authenticated user
      I want to be able to see the workplace configuration
    } do
      given(:user) { create :user }
      given(:workplace_count) { create :active_workplace_count, users: [user] }
      given!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }

      scenario 'Unauthenticated user tries to check configuration', js: true do
        visit edit_inventory_workplace_path(workplace)

        expect(page).to have_selector 'body#svt_sign_in'
        expect(page).to have_content 'Вам необходимо войти в систему'
      end

      scenario 'Authenticated user tries to check configuration', js: true do
        sign_in user
        visit edit_inventory_workplace_path(workplace)

        expect(page).to have_content 'Данные о рабочем месте'
        expect(page).to have_select 'Тип рабочего места', selected: workplace.workplace_type.long_description
        expect(page).to have_select 'Вид выполняемой работы', selected: workplace.workplace_specialization.short_description
        expect(page).to have_select 'Площадка', selected: workplace.iss_reference_site.name
        expect(page).to have_select 'Корпус', selected: workplace.iss_reference_building.name
        expect(page).to have_field 'Комната', with: workplace.iss_reference_room.name

        expect(page).to have_content 'Состав рабочего места'
        within '#wp_item_list' do
          expect(all('li').count).to eq workplace.inv_items.count
          expect(page).to have_field 'Инвентарный номер', with: workplace.inv_items.first.invent_num
          expect(page).to have_content 'Модель'

          workplace.inv_items.first.inv_properties.reject{ |prop| !prop.mandatory || prop.name == 'config_file' }.each do |prop|
            expect(page).to have_content prop.short_description
          end
        end
      end
    end
  end
end
