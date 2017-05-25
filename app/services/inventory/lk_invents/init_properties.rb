module Inventory
  module LkInvents
    # Загрузить все типы оборудования, типы РМ, их возможные свойства, виды деятельности и расположения.
    class InitProperties
      attr_reader :data

      # Опционально:
      # - если установлен id_tn - загрузить список отделов, которые указанный пользователь может редактировать
      # - если установлен division - загрузить список работников отдела.
      def initialize(id_tn = nil, division = nil)
        @data = {}
        @id_tn = id_tn
        @division = division
      end

      # mandatory - свойство mandatory таблицы invent_property
      def run(mandatory = false)
        load_divisions if @id_tn
        load_inv_types
        load_workplace_types
        load_workplace_specializations
        load_locations
        load_users if @division

        exclude_mandatory_fields unless mandatory
      rescue Exception => e
        Rails.logger.info e.inspect
        Rails.logger.info e.backtrace.inspect

        false
      end

      private

      # Получить список отделов, доступных на редактирование для указанного пользователя.
      def load_divisions
        @divisions = WorkplaceResponsible
                       .left_outer_joins(:workplace_count)
                       .select('invent_workplace_count.workplace_count_id, invent_workplace_count.division,
  invent_workplace_count.time_start, invent_workplace_count.time_end')
                       .where(id_tn: @id_tn)

        add_allowed_time
      end

      def add_allowed_time
        @data[:divisions] = @divisions.as_json.each do |division|
          division['allowed_time'] = time_not_passed?(division['time_start'], division['time_end'])

          division.delete('time_start')
          division.delete('time_end')
        end
      end

      # Проверка, входит ли текущее время в указанный интервал (true - если входит). Другими словами, не прошел ли срок
      # ввода данных.
      def time_not_passed?(time_start, time_end)
        Time.zone.today >= time_start && Time.zone.today <= time_end
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_inv_types
        @data[:eq_types] = InvType
                             .includes(:inv_models, inv_properties: { inv_property_lists: :inv_model_property_lists })
                             .where('name != "unknown"')
      end

      def load_workplace_types
        # Получить список типов РМ.
        @wp_types = WorkplaceType.all
        @data[:wp_types] = @wp_types.as_json.each do |type|
          type['full_description'] = WorkplaceType::DESCR[type['name'].to_sym]
        end
      end

      # Получить список направлений.
      def load_workplace_specializations
        @data[:specs] = WorkplaceSpecialization.all
      end

      # Получить список площадок и корпусов.
      def load_locations
        @data[:iss_locations] = IssReferenceSite
                                  .includes(:iss_reference_buildings)
                                  .as_json(include: :iss_reference_buildings)
      end

      # Исключить все свойства inv_property, где mandatory = false (исключение для системных блоков).
      def exclude_mandatory_fields
        @data[:eq_types] = @data[:eq_types].as_json(
          include: {
            inv_properties: {
              include: {
                inv_property_lists: {
                  include: :inv_model_property_lists
                }
              }
            },
            inv_models: {}
          }
        ).each do |type|
          if InvPropertyValue::PROPERTY_WITH_FILES.none? { |val| val == type['name'] }
            type['inv_properties'].delete_if { |prop| !prop['mandatory'] }
          end

          type
        end
      end

      # Получить список работников указанного отдела
      def load_users
        @data[:users] = UserIss
                   .select(:id_tn, :fio)
                   .where(dept: @division)
      end
    end
  end
end
