module Inventory
  module LkInvents
    class BaseService
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

        prepare_to_***REMOVED***_table
      end

      # Создание необходимых для таблицы полей
      def prepare_to_***REMOVED***_table
        @data['short_description'] = @data['workplace_type']['short_description'] if @data['workplace_type']
        @data['fio'] = @data['user_iss']['fio_initials']
        @data['duty'] = @data['user_iss']['duty']
        @data['location'] = "Пл. '#{@data['iss_reference_site']['name']}', корп.
#{@data['iss_reference_building']['name']}, комн. #{@data['iss_reference_room']['name']}"
        @data['status'] = Workplace.translate_enum(:status, @data['status'])

        @data.delete('iss_reference_site')
        @data.delete('iss_reference_building')
        @data.delete('iss_reference_room')
        @data.delete('user_iss')
        @data.delete('workplace_type')

        @data
      end
    end
  end
end
