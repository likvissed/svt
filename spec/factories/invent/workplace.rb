module Invent
  FactoryBot.define do
    factory :workplace, class: Workplace do
      workplace_count { WorkplaceCount.find_by(division: dept) || create(:active_workplace_count, :default_user, division: dept) }
      workplace_specialization { WorkplaceSpecialization.last }
      user_iss { UserIss.find_by(dept: workplace_count.division) }
      iss_reference_site { IssReferenceSite.first }
      iss_reference_building { iss_reference_site.iss_reference_buildings.first }
      iss_reference_room { iss_reference_building.iss_reference_rooms.first }
      comment ''
      status :pending_verification
      enabled_filters true

      transient do
        # Отдел по умолчанию
        dept ***REMOVED***
      end

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

      trait :add_items do
        transient do
          # Массив типов создаваемых экземпляров техники.
          # В качестве элемента массива может быть Hash и Symbol.
          # Если Symbol: указывается тип создаваемого оборудования в соответствии с полем name таблицы invent_type.
          # Если Hash:
          #   - ключ: имя типа создаваемого оборудования в соответствии с полем name таблицы invent_type
          #   - значение: массив, содержащий объекты Hash, у которых ключ - это имя свойства создаваемого типа
          #       оборудования, а значение - значение свойства (могут быть: 1. Объекты модели PropertyList.
          #       2. Строковые значения).
          #
          # item.keys[0] - ключ хэша
          # item[item.keys[0]] - значение ключа
          items []
        end

        after(:build) do |workplace, evaluator|
          evaluator.items.each do |item|
            case item
            when Hash
              workplace.items << build(
                :item, :with_property_values, model: nil, item_model: 'my model', type_name: item.keys[0], property_values: item[item.keys[0]]
              )
            when Symbol || String
              workplace.items << build(:item, :with_property_values, model: nil, item_model: 'my model', type_name: item)
            end
          end
        end
      end

      factory :workplace_pk, traits: [:rm_pk]
      factory :workplace_mob, traits: [:rm_mob]
      factory :workplace_net_print, traits: [:net_print]
      factory :workplace_server, traits: [:rm_server]
    end
  end
end
