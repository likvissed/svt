module Invent
  module Workplaces
    class BaseService < Invent::ApplicationService
      protected

      # Создать комнату (если она не существует). Создает объект @room.
      def create_or_get_room
        @room = Room.new(@workplace_params['location_room_name'], @workplace_params['location_building_id'], @workplace_params['room_category_id'])

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

      def fill_swap_arr
        @swap = []
        @workplace_params['items_attributes']&.delete_if { |i| @swap << i['id'] if i['status'] == 'prepared_to_swap' }
      end

      def swap_items
        swap = Warehouse::Orders::Swap.new(@current_user, @workplace.workplace_id, @swap)
        return true if swap.run

        # errors.add(:base, swap.error[:full_message])
        @error = swap.error
        raise 'Не удалось перенести технику'
      end

      # Отфильтровать полученные данные
      def run_filters
        @workplaces = @workplaces.filter(filtering_params)
      end

      def filtering_params
        JSON.parse(params[:filters]).slice('fullname', 'workplace_count_id', 'workplace_id', 'workplace_type_id', 'status', 'invent_num', 'location_building_id', 'location_room_id')
      end

      def init_workplace_templates
        @workplace ||= Workplace.new
        data[:item] = @workplace.items.build(status: :in_workplace).as_json
        data[:item]['property_values_attributes'] = []
        data[:item]['id'] = nil

        data[:property_value] = PropertyValue.new.as_json
        data[:property_value]['id'] = nil
      end

      # Загрузить данные для фильтров
      def load_filters
        data[:filters] = {}
        data[:filters][:divisions] = policy_scope(WorkplaceCount).select(:workplace_count_id, :division).order('CAST(division AS SIGNED)')
        data[:filters][:statuses] = workplace_statuses
        data[:filters][:types] = WorkplaceType.select(:workplace_type_id, :short_description)
        data[:filters][:buildings] = IssReferenceBuilding
                                       .select('iss_reference_sites.name as site_name, iss_reference_buildings.*')
                                       .left_outer_joins(:iss_reference_site)
        data[:filters][:priorities] = item_priorities
      end
    end
  end
end
