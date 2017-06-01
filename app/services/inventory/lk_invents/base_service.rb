module Inventory
  module LkInvents
    class BaseService < ApplicationService
      private

      # Подготовка параметров к записи: получение room_id, запись файла в параметры.
      def prepare_params
        create_or_get_room
        if @file.kind_of?(ActionDispatch::Http::UploadedFile) || @file.kind_of?(Rack::Test::UploadedFile)
          set_file_into_params
        end
      end

      # Записать файл в @workplace_params.
      # 1. Ищется 'item' с типом, который содержит свойство 'Отчет о конфигурации'
      # 2. В найденном 'item' ищется 'inv_property_value' со свойством 'Отчет о конфигурации'
      # 3. Создается ключ ':file', в который записывается файл. В ключ ':value' записывается имя файла.
      def set_file_into_params
        type_with_files = InvType.where(name: InvPropertyValue::PROPERTY_WITH_FILES).includes(:inv_properties)

        @workplace_params[:inv_items_attributes].each do |item|
          next if (type = type_with_files.find { |type| type[:type_id] == item[:type_id] }).nil?

          item[:inv_property_values_attributes].each do |prop_val|
            next unless type.inv_properties.find { |prop| prop[:property_id] == prop_val[:property_id] }.name == 'config_file'

            prop_val[:file] = @file
            prop_val[:value] = @file.original_filename

            break
          end
        end
      end

      # Создать комнату (если она не существует). Создает объект @room.
      def create_or_get_room
        @room = Room.new(@workplace_params[:location_room_name], @workplace_params[:location_building_id])

        @workplace_params[:location_room_id] = @room.data.room_id if @room.run
      end

      # Преобразование объекта workplace в специальный вид, чтобы таблица могла отобразить данные.
      def prepare_workplace
        @data = @workplace.as_json(
          include: {
            iss_reference_site: {},
            iss_reference_building: {},
            iss_reference_room: {},
            user_iss: {},
            workplace_type: {},
            inv_items: {
              include: {
                inv_type: {},
                inv_property_values: {
                  include: :inv_property
                }
              }
            }
          }
        )

        @data = prepare_to_***REMOVED***_table(@data)
      end

      def prepare_to_***REMOVED***_table(wp)
        wp['short_description'] = wp['workplace_type']['short_description'] if wp['workplace_type']
        wp['fio'] = wp['user_iss']['fio_initials']
        wp['duty'] = wp['user_iss']['duty']
        wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп.
#{wp['iss_reference_building']['name']}, комн. #{wp['iss_reference_room']['name']}"
        wp['status'] = Workplace.translate_enum(:status, wp['status'])

        wp.delete('iss_reference_site')
        wp.delete('iss_reference_building')
        wp.delete('iss_reference_room')
        wp.delete('user_iss')
        wp.delete('workplace_type')

        wp
      end
    end
  end
end
