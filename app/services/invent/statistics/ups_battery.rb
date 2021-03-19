module Invent
  module Statistics
    class UpsBattery < Invent::ApplicationService
      def initialize
        super
      end

      def run
        load_critical_ups
        process_data

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_critical_ups
        @type = Invent::Type.find_by(name: :ups)
        @property_battery_type = @type.properties.find_by(name: :battery_type)
        @property_battery_count = @type.properties.find_by(name: :battery_count)
        @property_battery_module = @type.properties.find_by(name: :battery_module)
        @property_replacement_date = @type.properties.find_by(name: :replacement_date)

        @data = @property_battery_type.property_lists.map do |prop_list|
          {
            id: prop_list.property_list_id,
            value: prop_list.value,
            description: prop_list.short_description,
            total_count: 0,
            to_replace_count: 0
          }
        end
      end

      def process_data
        # Массив id типов батарей, которые используются в invent_item
        # для того, чтобы не выполнять лишний запрос, если нет техники с каким-то типом батарей
        arr_present_type = Invent::PropertyList
                             .includes(
                               :property,
                               { property_values: :item }
                             )
                             .where(property_values: { invent_item: { priority: 2, type_id: @type.id } })
                             .where(property: @property_battery_type)
                             .pluck(:property_list_id).uniq

        # Массив значений для свойства "Тип батарей"
        arr_prop_values = Invent::PropertyValue
                            .includes(
                              :property,
                              :property_list,
                              { item: :type }
                            )
                            .where(property: @property_battery_type)
                            .where(invent_item: { priority: 2, type_id: @type.id })

        @data.each do |dt|
          # Пропустить, если текущий тип батарей не используется в техники
          next if arr_present_type.exclude?(dt[:id])

          # Массив значений для текущего типа батарей
          property_values = arr_prop_values.where(property_list_id: dt[:id])

          next if property_values.blank?

          # Для дальнейшей фильтрации по нужной техники, получает массив из id invent_item
          ids_items = property_values.map { |pv| pv.item.item_id }

          # Все значения для каждой техники
          all_property_values = Invent::PropertyValue
                                  .includes(:item, :property, :property_list)
                                  .where(item: [ids_items])

          # Массив значений по свойству "Дата последней замены батарей"
          arr_property_replacement_date = all_property_values.where(property: @property_replacement_date)

          # Получение id invent_item, для которых необходимо заменить батареи
          ids_items_need_battery_replacement = check_need_battery_replacement(arr_property_replacement_date)

          # Массив значений по свойству "Количество батарей"
          arr_property_battery_count = all_property_values.where(property: @property_battery_count)
          arr_property_battery_count.each do |prop_val|
            count = prop_val&.property_list&.value.to_i

            dt[:to_replace_count] += count if ids_items_need_battery_replacement.include?(prop_val.item.item_id)
            dt[:total_count] += count
          end

          # Массив значений по свойству "Внешний батарейный модуль"
          arr_property_battery_module = all_property_values.where(property: @property_battery_module)
          arr_property_battery_module.each do |prop_val|
            count = prop_val&.value.to_i

            dt[:to_replace_count] += count if ids_items_need_battery_replacement.include?(prop_val.item.item_id)
            dt[:total_count] += count
          end
        end
      end

      # Проверяет необходимость замены батарей
      def check_need_battery_replacement(property_values)
        ids_items = []
        property_values.each do |prop_val|
          value = prop_val.value

          # Добавить технику в подсчет замены батарей, если:
          #  1 - данных нет
          #  2,3 - с даты последней замены прошло более 3 или 5 лет
          next unless value.blank? || (battery_difference_in_years(value) > Invent::Item::LEVELS_BATTERY_REPLACEMENT[:critical]) ||
                      (battery_difference_in_years(value) > Invent::Item::LEVELS_BATTERY_REPLACEMENT[:warning])

          ids_items << prop_val.item_id
        end

        ids_items
      end

      # Возвращает сколько полных лет назад производилась замена батарей.
      def battery_difference_in_years(date)
        # Если передан параметр не являющийся датой, вернуть zero
        return 0 if Date._parse(date.to_s).blank?

        current_date = Time.zone.now
        replacement_date = Date.parse(date)

        d = (replacement_date.year - current_date.year).abs
        d -= 1 if replacement_date.month > current_date.month
        d
      end
    end
  end
end
