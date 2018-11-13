desc "Преобразовать строковые значения даты (в таблице invent_property_value), чтобы в дальнейшем можно было с ними работать как с объектами даты в JS"
namespace :db do
  task transform_property_value_to_date: :environment do
    property = Invent::Type.find_by(name: :printer).properties.find_by(name: :date)
    prop_vals = property.property_values.where('value != ""')

    prop_vals.find_each do |prop_val|
      res = /(\d+)\.(\d+)\.(\d+)/.match(prop_val.value)
      next unless res

      year = res[3].size == 2 ? "20#{res[3]}" : res[3]
      month = res[2].size == 1 ? "0#{res[2]}" : res[2]
      day = res[1].size == 1 ? "0#{res[1]}" : res[1]

      new_date = "#{year}-#{month}-#{day}T00:00:00.000Z"
      prop_val.update(value: new_date)
    end
  end
end
