module Invent
  module LkInvents
    # Загрузить все типы оборудования, типы РМ, их возможные свойства, виды деятельности и расположения.
    class InitProperties < BaseService
      # Опционально:
      # - если установлен current_user - загрузить список отделов, которые указанный пользователь может редактировать
      # - если установлен division - загрузить список работников отдела.
      def initialize(current_user = nil, division = nil)
        @data = {}
        @current_user = current_user
        @division = division
      end

      def run
        load_divisions if @current_user
        load_types
        load_workplace_types
        load_workplace_specializations
        load_locations
        load_statuses
        load_item_move_types
        load_users if @division
        load_constants
        load_security_categories
        prepare_eq_types_to_render
        load_priorities

        true
      rescue Pundit::NotAuthorizedError
        false
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_types
        data[:eq_types] = Type
                            .includes(:models, properties: { property_lists: :model_property_lists })
      end

      # Преобразовать в json формат с необходимыми полями.
      def prepare_eq_types_to_render
        data[:eq_types] = data[:eq_types].as_json(
          include: [
            :models,
            properties: {
              include: {
                property_lists: {
                  include: :model_property_lists
                }
              }
            }
          ]
        )
      end

      # Получить список площадок и корпусов.
      def load_locations
        data[:iss_locations] = IssReferenceSite
                                 .order(:sort_order)
                                 .includes(iss_reference_buildings: :iss_reference_rooms)
                                 .as_json(include: {
                                            iss_reference_buildings: {
                                              include: :iss_reference_rooms
                                            }
                                          })

        data[:iss_locations].each do |loc|
          loc['name'] = "#{loc['name']} (#{loc['long_name']})" unless loc['long_name'].to_s.empty?
        end
      end

      protected

      # Получить список отделов, доступных на редактирование для указанного пользователя.
      def load_divisions
        @divisions = policy_scope(WorkplaceCount).order('CAST(division AS UNSIGNED)')
        raise Pundit::NotAuthorizedError, 'Access denied' if @divisions.empty?

        data[:divisions] = @divisions.as_json.each do |division|
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

      def load_workplace_types
        # Получить список типов РМ.
        @wp_types = WorkplaceType.all
        data[:wp_types] = @wp_types.as_json.each do |type|
          type['full_description'] = WorkplaceType::DESCR[type['name'].to_sym]
        end
      end

      # Получить список направлений.
      def load_workplace_specializations
        data[:specs] = WorkplaceSpecialization.all
      end

      # Получить список возможных статусов РМ.
      def load_statuses
        data[:statuses] = workplace_statuses
      end

      # Получить список статусов техники, обозначающих перемещение.
      def load_item_move_types
        data[:move_item_types] = Item::MOVE_ITEM_TYPES
      end

      # Получить список приоритетов.
      def load_priorities
        data[:priorities] = item_priorities
      end

      # Получить различные константы, необходимые для работы
      def load_constants
        data[:file_depending] = Property::FILE_DEPENDING
        data[:date_props] = Property::DATE_PROPS
        data[:single_pc_items] = Type::SINGLE_PC_ITEMS
        data[:type_with_files] = Type::TYPE_WITH_FILES
        data[:message_for_security_category] = WorkplaceType::SECURITY_ROOM
      end

      # Загрузить все категории секретности
      def load_security_categories
        data[:rooms_security_categories] = RoomSecurityCategory.all
      end
    end
  end
end
