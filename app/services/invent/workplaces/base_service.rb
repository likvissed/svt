module Invent
  module Workplaces
    class BaseService < Invent::ApplicationService
      protected

      # # Создать комнату (если она не существует). Создает объект @room.
      # def create_or_get_room
      #   @room = Room.new(@workplace_params['location_room_name'], @workplace_params['location_building_id'], @workplace_params['room_category_id'])

      #   @workplace_params['location_room_id'] = @room.data.room_id if @room.run
      # end

      # Преобразование объекта workplace в специальный вид, чтобы таблица могла отобразить данные.
      def prepare_workplace
        @data = @workplace.as_json(
          include: [
            :iss_reference_site,
            :iss_reference_building,
            :iss_reference_room,
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
        data[:users] = UsersReference.info_users("departmentForAccounting==#{@division}").map { |employee| employee.slice('fullName', 'id') }
      end

      def find_employees_page
        employee_list = @workplaces.map(&:id_tn)

        @employees_wp = UsersReference.info_users("id=in=(#{employee_list.compact.join(',')})")
      end

      # Возвращает ФИО ответственного
      def fio_employee(wp)
        employee = @employees_wp.find { |emp| emp['id'] == wp['id_tn'] }

        if employee.present?
          employee['fullName']
        else
          []
        end
      end

      # Возвращает строку, содержащую расположение РМ.
      def wp_location_string(wp)
        if wp['iss_reference_room'].nil?
          'Не назначено'
        else
          "Пл. '#{wp['iss_reference_site']['name']}', корп. '#{wp['iss_reference_building']['name']}', комн. '#{wp['iss_reference_room']['name']}'"
        end
      end

      def assing_barcode
        @workplace_params['items_attributes'].each do |item|
          next if item['barcode_item_attributes'].present?

          item['barcode_item_attributes'] = Barcode.new(codeable_type: 'Invent::Item').as_json
        end
      end

      def delete_property_value
        @workplace_params['items_attributes'].each do |item|
          next if item['property_values_attributes'].blank?

          item['property_values_attributes'] = delete_blank_and_assign_barcode_prop_value(item['property_values_attributes'])
        end
      end

      # Добавить файлы вложения при обновлении и создании РМ
      def create_attachments
        @workplace_attachments.each { |att| @workplace.attachments.create(document: att) }
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
        JSON.parse(params[:filters]).slice('fullname', 'workplace_count_id', 'workplace_id', 'workplace_type_id', 'status', 'invent_num', 'location_building_id', 'location_room_id', 'show_only_with_attachments')
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
