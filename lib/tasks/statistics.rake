require 'csv'

namespace :statistics do
  desc 'Получить статистику по указанной технике для указанного отдела'
  task :equipment_by_division, [:dept, :type] => [:environment] do |task, args|
    CSV.open('statistics.csv', 'w:UTF-8', col_sep: '|') do |file|
      @division = Invent::WorkplaceCount.find_by(division: args[:dept])
      @type = Invent::Type.find_by(name: args[:type])
      @workplaces = Invent::Workplace.where(workplace_count: @division).includes(:items)

      result = []
      @workplaces.each do |wp|
        result << wp.items.where(type_id: @type.type_id).includes(:property_values).map do |item|
          {
            id: wp.workplace_id,
            invent_num: item.invent_num,
            config: item.full_item_model
          }
        end
      end

      file << %w[ID инв№ Характеристики]
      result.flatten.each do |res|
        file << [res[:id], res[:invent_num], res[:config]]
      end
    end
  end
end
