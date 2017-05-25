module Inventory
  module LkInvents
    # Создать рабочее место. Здесь устанавливаются все необходимые параметры (id комнаты, файл), выполняется логирование
    # полученных данных и создается рабочее место.
    class CreateWorkplace < BaseService
      include ActiveModel::Validations

      attr_reader :workplace_params, :workplace, :data

      def initialize(strong_params, file = nil)
        @workplace_params = strong_params.with_indifferent_access
        @file = file
      end

      def run
        create_or_get_room
        if @file.kind_of?(ActionDispatch::Http::UploadedFile) || @file.kind_of?(Rack::Test::UploadedFile)
          set_file_into_params
        end
        @workplace = Workplace.new(@workplace_params)
        log_data
        save_workplace
      rescue RuntimeError
        false
      end

      private

      # Создать комнату (если она не существует). Создает объект @room.
      def create_or_get_room
        @room = Room.new(
          @workplace_params[:location_room_name],
          @workplace_params[:location_building_id]
        )

        @workplace_params[:location_room_id] = @room.data.room_id if @room.run
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

      # Логирование полученных данных.
      def log_data
        Rails.logger.info "Workplace: #{@workplace.inspect}".red
        @workplace.inv_items.each_with_index do |item, item_index|
          Rails.logger.info "Item [#{item_index}]: #{item.inspect}".green

          item.inv_property_values.each_with_index do |val, prop_index|
            Rails.logger.info "Prop_value [#{prop_index}]: #{val.inspect}".cyan
          end
        end
      end

      # Создать рабочее место.
      def save_workplace
        if @workplace.save
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                        .includes(inv_items: [:inv_type, { inv_property_values: :inv_property }])
                        .find(@workplace.workplace_id)

          prepare_workplace
        else
          Rails.logger.info @workplace.errors.full_messages.inspect.blue

          errors.add(:base, @workplace.errors.full_messages.join(', '))
          raise 'abort'
        end
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
    end
  end
end
