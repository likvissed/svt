module Invent
  FactoryBot.define do
    factory :item, class: Item do
      parent_id { 0 }
      type { Type.find_by(name: type_name) }
      workplace { nil }
      location { 'Location' }
      model { type.try(:models).try(:first) }
      item_model { '' }
      sequence(:invent_num) { |i| 764_196 + i }
      sequence(:serial_num) { |i| 222_222 + i }

      transient do
        # Имя типа, указанное в таблице invent_type (поле name).
        type_name { nil }
        # Массив объектов, ключ - имя свойства, значение - хэш { property_list: obj, value: '' }.
        property_values { [] }
      end

      # Ситуация, когда пользователь заполнил поля.
      trait :with_property_values do
        after(:build) do |item, evaluator|
          item.properties.each do |prop|
            if evaluator.property_values.empty?
              # Если property_values пуст, создать дефотлные значения.
              case prop.property_type
              when 'string'
                item.property_values << build(
                  :property_value, item: item, property: prop, value: 'String value'
                )
              when 'list', 'list_plus'
                item.property_values << build(
                  :property_value, item: item, property: prop, property_list: prop.property_lists.first
                )
              when 'file'
                item.property_values << build(
                  :property_value, item: item, property: prop, value: 'old_pc_config.txt'
                )
              when 'date', 'date_month'
                item.property_values << build(
                  :property_value, item: item, property: prop, value: Time.zone.now
                )
              end
            else
              setting_prop = evaluator.property_values.find { |prop_val| prop_val.keys.first.to_sym == prop.name.to_sym }
              # Если property_value задано, необходимо создать invent_property_value со значениями указанными в setting_prop
              if setting_prop
                case prop.property_type
                when 'string', 'date', 'date_month'
                  item.property_values << build(
                    :property_value, item: item, property: prop, value: setting_prop[prop.name.to_sym][:value]
                  )
                when 'list'
                  item.property_values << build(
                    :property_value, item: item, property: prop, property_list: setting_prop[prop.name
                      .to_sym][:property_list]
                  )
                when 'list_plus'
                  item.property_values << build(
                    :property_value, item: item, property: prop, property_list: setting_prop[prop.name
                      .to_sym][:property_list], value: setting_prop[prop.name.to_sym][:value]
                  )
                when 'file'
                  item.property_values << build(
                    :property_value, item: item, property: prop, value: setting_prop[prop.name.to_sym][:value]
                  )
                end
              else
                case prop.property_type
                when 'string'
                  item.property_values << build(
                    :property_value, item: item, property: prop, value: 'String value'
                  )
                when 'list', 'list_plus'
                  item.property_values << build(
                    :property_value, item: item, property: prop, property_list: prop.property_lists.first
                  )
                when 'file'
                  item.property_values << build(
                    :property_value, item: item, property: prop, value: 'old_pc_config.txt'
                  )
                when 'date', 'date_month'
                  item.property_values << build(
                    :property_value, item: item, property: prop, value: Time.zone.now
                  )
                end
              end
            end
          end
        end
      end

      # Ситуация, когда пользователь не заполнил поля.
      trait :without_property_values do
        after(:build) do |item|
          item.properties.each do |prop|
            case prop.property_type
            when 'string'
              item.property_values << build(:property_value, item: item, property: prop)
            when 'list'
              item.property_values << build(:property_value, item: item, property: prop)
            when 'list_plus'
              item.property_values << build(:property_value, item: item, property: prop)
            when 'file'
              item.property_values << build(:property_value, item: item, property: prop)
            end
          end
        end
      end
    end
  end
end
