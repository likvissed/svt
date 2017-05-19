module Inventory
  FactoryGirl.define do
    factory :item, class: InvItem do
      parent_id 0
      workplace_id 0
      location 'Location'
      model_id 0
      item_model ''
      invent_num '764196'
      serial_num '222222'
      inv_type { InvType.find_by(name: type_name) }

      transient do
        # Имя типа, указанное в таблице invent_type (поле name).
        type_name nil
        # Массив объектов, ключ - имя свойства, значение - хэш { inv_property_list: obj, value: '' }.
        property_values []
      end

      trait :without_model_id do
        model_id -1
      end

      # Если пользователь выбрал модель.
      trait :with_model_id do
        model_id { inv_type.inv_models.first.model_id }
      end

      # Если пользователь
      trait :with_item_model do
        item_model 'My model'
      end

      # Ситуация, когда пользователь заполнил поля.
      trait :with_property_values do
        after(:build) do |item, evaluator|
          Inventory::InvType.find_by(name: evaluator.type_name).inv_properties.each do |prop|
            if evaluator.property_values.empty?
              # Если property_values пуст, создать дефотлные значения.
              case prop.property_type
              when 'string'
                item.inv_property_values << build(
                  :property_value, inv_item: item, inv_property: prop, value: 'String value'
                )
              when 'list'
                item.inv_property_values << build(
                  :property_value, inv_item: item, inv_property: prop, inv_property_list: prop.inv_property_lists.first
                )
              when 'list_plus'
                item.inv_property_values << build(
                  :property_value, inv_item: item, inv_property: prop, inv_property_list: prop.inv_property_lists.first
                )
              when 'file'
                item.inv_property_values << build(
                  :property_value, inv_item: item, inv_property: prop, value: 'file_name.txt'
                )
              end
            else
              # Если property_value задано, необходимо создать invent_property_value со значениями указанными в
              evaluator.property_values.each do |setting_prop|
                next unless setting_prop.keys.first.to_sym == prop.name.to_sym

                case prop.property_type
                when 'string'
                  item.inv_property_values << build(
                    :property_value, inv_item: item, inv_property: prop, value: setting_prop[prop.name.to_sym][:value]
                  )
                when 'list'
                  item.inv_property_values << build(
                    :property_value, inv_item: item, inv_property: prop, inv_property_list: setting_prop[prop.name
                    .to_sym][:inv_property_list]
                  )
                when 'list_plus'
                  item.inv_property_values << build(
                    :property_value, inv_item: item, inv_property: prop, inv_property_list: setting_prop[prop.name
                    .to_sym][:inv_property_list], value: setting_prop[prop.name.to_sym][:value]
                  )
                when 'file'
                  item.inv_property_values << build(
                    :property_value, inv_item: item, inv_property: prop, value: setting_prop[prop.name.to_sym][:value]
                  )
                end

                break
              end
            end
          end
        end
      end

      # Ситуация, когда пользователь не заполнил поля.
      trait :without_property_values do
        after(:build) do |item, evaluator|
          Inventory::InvType.find_by(name: evaluator.type_name).inv_properties.each do |prop|
            case prop.property_type
            when 'string'
              item.inv_property_values << build(:property_value, inv_item: item, inv_property: prop)
            when 'list'
              item.inv_property_values << build(:property_value, inv_item: item, inv_property: prop)
            when 'list_plus'
              item.inv_property_values << build(:property_value, inv_item: item, inv_property: prop)
            when 'file'
              item.inv_property_values << build(:property_value, inv_item: item, inv_property: prop)
            end
          end
        end
      end

      # Ситуация, когда пользователь не загрузил файл, но заполнил остальные поля (получил данные от Аудита).
      trait :with_property_values_and_without_file do
        after(:build) do |item, evaluator|
          Inventory::InvType.find_by(name: evaluator.type_name).inv_properties.each do |prop|
            case prop.property_type
            when 'string'
              item.inv_property_values << build(
                :property_value, inv_item: item, inv_property: prop, value: 'String value'
              )
            when 'list'
              item.inv_property_values << build(
                :property_value, inv_item: item, inv_property: prop, inv_property_list: prop.inv_property_lists.first
              )
            when 'list_plus'
              item.inv_property_values << build(
                :property_value, inv_item: item, inv_property: prop, inv_property_list: prop.inv_property_lists.first
              )
            when 'file'
              item.inv_property_values << build(:property_value, inv_item: item, inv_property: prop)
            end
          end
        end
      end

      # Ситуация, когда пользователь загрузил файл и не заполнил поля.
      # Свойства с типом list и list_plus нужно заполнить, так как для типа данные ПК заполняются только в string
      # полях. Соотвтетсвенно для теста необходимо, что только string поля были пустыми.
      trait :without_property_values_and_with_file do
        after(:build) do |item, evaluator|
          Inventory::InvType.find_by(name: evaluator.type_name).inv_properties.each do |prop|
            case prop.property_type
            when 'string'
              item.inv_property_values << build(:property_value, inv_item: item, inv_property: prop)
            when 'list'
              item.inv_property_values << build(
                :property_value, inv_item: item, inv_property: prop, inv_property_list: prop.inv_property_lists.first
              )
            when 'list_plus'
              item.inv_property_values << build(
                :property_value, inv_item: item, inv_property: prop, inv_property_list: prop.inv_property_lists.first
              )
            when 'file'
              item.inv_property_values << build(
                :property_value, inv_item: item, inv_property: prop, value: 'file_name.txt'
              )
            end
          end
        end
      end

      # Фабрика с заполненными свойствами
      factory :item_with_item_model, traits: [:with_item_model]
      factory :item_with_model_id, traits: [:with_model_id]
    end
  end
end
