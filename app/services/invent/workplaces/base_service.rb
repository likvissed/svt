module Invent
  module Workplaces
    class BaseService < Invent::ApplicationService
      private

      # Создать комнату (если она не существует). Создает объект @room.
      def create_or_get_room
        @room = Room.new(@workplace_params['location_room_name'], @workplace_params['location_building_id'])

        @workplace_params['location_room_id'] = @room.data.room_id if @room.run
      end

      # Преобразование объекта workplace в специальный вид, чтобы таблица могла отобразить данные.
      def prepare_workplace
        @data = @workplace.as_json(
          include: [
            :iss_reference_site,
            :iss_reference_building,
            :iss_reference_room,
            :user_iss,
            :workplace_type,
            items: {
              include: [
                :type,
                property_values: {
                  include: :property
                }
              ]
            }
          ]
        )

        @data = prepare_to_***REMOVED***_table(@data)
      end

      # Получить список работников указанного отдела.
      def load_users
        data[:users] = UserIss.select(:id_tn, :fio).where(dept: @division)
      end

      # Возвращает строку, содержащую расположение РМ.
      def wp_location_string(wp)
        "Пл. '#{wp['iss_reference_site']['name']}', корп. '#{wp['iss_reference_building']['name']}', комн. '#{wp['iss_reference_room']['name']}'"
      end
    end
  end
end
