module Inventory
  FactoryGirl.define do
    factory :workplace, class: Workplace do
      workplace_specialization { WorkplaceSpecialization.last }
      id_tn 0
      iss_reference_site { loc_site }
      iss_reference_building { loc_building }
      iss_reference_room { loc_room }
      comment ''
      status { Workplace.statuses['В ожидании проверки'] }

      trait :rm_pk do
        workplace_type { WorkplaceType.find_by(name: 'rm_pk') }
      end

      trait :rm_mob do
        workplace_type { WorkplaceType.find_by(name: 'rm_mob') }
      end

      trait :net_print do
        workplace_type { WorkplaceType.find_by(name: 'rm_net_print') }
      end

      trait :rm_server do
        workplace_type { WorkplaceType.find_by(name: 'rm_server') }
      end

      trait :active do
        association :workplace_count, factory: :active_workplace_count
      end

      transient do
        loc_site { IssReferenceSite.first }
        loc_building { loc_site.iss_reference_buildings.first }
        loc_room { loc_building.iss_reference_rooms.first }
      end

      trait :add_items do
        transient do
          # Массив типов создаваемых экземпляров техники.
          # В качестве элемента массива может быть Hash и Symbol.
          # Если Symbol: указывается тип создаваемого оборудования в соответствии с полем name таблицы invent_type.
          # Если Hash:
          #   - ключ: имя типа создаваемого оборудования в соответствии с полем name таблицы invent_type
          #   - значение: массив, содержащий объекты Hash, у которых ключ - это имя свойства создаваемого типа
          #       оборудования, а значение - значение свойства.
          items []
        end

        after(:build) do |workplace, evaluator|
          evaluator.items.each do |item|
            case item
            when Hash
              workplace.inv_items << build(
                :item_with_item_model, :with_property_values, type_name: item.keys[0], property_values: item[item
                .keys[0]]
              )
            when Symbol || String
              workplace.inv_items << build(:item_with_item_model, :with_property_values, type_name: item)
            end
          end
        end
      end
    end

    # РМ с верно заполненными аттрибутами.
    factory :full_workplace, parent: :workplace do
      active
      id_tn { UserIss.where(dept: workplace_count.division).where('tn < 100000').first.id_tn }

      factory :full_workplace_rm_pk,        traits: [:rm_pk]
      factory :full_workplace_rm_mob,       traits: [:rm_mob]
      factory :full_workplace_rm_net_print, traits: [:net_print]
      factory :full_workplace_rm_server,    traits: [:rm_server]
    end

    # РМ с неверно заполненными аттрибутами.
    factory :workplace_with_wrong_id_tn, parent: :workplace do
      active
      rm_pk
      id_tn 987_654_321
    end
  end
end
