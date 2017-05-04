module Inventory
  class LkInventsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token
    before_action :check_***REMOVED***_authorization
    authorize_resource class: false, param_method: :workplace_params
    before_action :check_workplace_count_access, only: %i[create_workplace update_workplace destroy_workplace]
    before_action :check_timeout, except: %i[init show_division_data data_from_audit send_pc_script]
    after_action -> { sign_out @user }

    # Табельный номер пользователя в таблице users, от имени которого пользователи ЛК получают доступ в систему.
    @tn_***REMOVED***_user = 999_999

    # Получить список отделов, закрепленных за пользователем и список всех типов оборудования с их параметрами.
    def init
      # Получить список отделов
      @divisions = WorkplaceResponsible
                     .left_outer_joins(:workplace_count)
                     .select('invent_workplace_count.workplace_count_id, invent_workplace_count.workplace_count_id,
invent_workplace_count.division, invent_workplace_count.time_start, invent_workplace_count.time_end')
                     .where(id_tn: params[:id_tn])

      # Проверка, прошел ли срок редактирования для каждого полученного отдела. Результат записывается в переменную
      # allowed_time.
      @divisions = @divisions.as_json.each do |division|
        division['allowed_time'] = time_not_passed?(division['time_start'], division['time_end'])

        division.delete('time_start')
        division.delete('time_end')
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      @inv_types = InvType
                     .includes(:inv_models, inv_properties: { inv_property_lists: :inv_model_property_lists })
                     .where('name != "unknown"')

      # Получить список типов РМ.
      @wp_types = WorkplaceType.all
      @wp_types = @wp_types.as_json.each { |type| type['full_description'] = WorkplaceType::DESCR[type['name'].to_sym] }

      # Получить список направлений.
      @specs = WorkplaceSpecialization.all

      # Получить список площадок и корпусов.
      @iss_locations = IssReferenceSite.includes(:iss_reference_buildings)

      # Исключить все свойства inv_property, где mandatory = false (исключение для системных блоков).
      types = @inv_types.as_json(
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
          type['inv_properties'].delete_if { |prop| prop['mandatory'] == false }
        end

        type
      end

      data = {
        divisions: @divisions,
        eq_types: types,
        wp_types: @wp_types,
        specs: @specs,
        iss_locations: @iss_locations.as_json(include: :iss_reference_buildings)
      }
      render json: data, status: 200
    end

    # Получить данные по выбранном отделу (список РМ, макс. число, список работников отдела).
    def show_division_data
      # Получить рабочие места указанного отдела
      @workplaces = Workplace
                      .includes(:iss_reference_site, :iss_reference_building, :iss_reference_room, :user_iss)
                      .left_outer_joins(:workplace_count, :workplace_type)
                      .select('invent_workplace.*, invent_workplace_type.name as type_name, invent_workplace_type' \
'.short_description')
                      .where('invent_workplace_count.division = ?', params[:division])
                      .order(:workplace_id)

      @workplaces = @workplaces.as_json(
        include: %i[iss_reference_site iss_reference_building iss_reference_room user_iss]
      ).each do |wp|
        wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']},
комн. #{wp['iss_reference_room']['name']}"
        wp['fio'] = wp['user_iss']['fio_initials']
        wp['user_tn'] = wp['user_iss']['tn']
        wp['duty'] = wp['user_iss']['duty']

        wp.delete('iss_reference_site')
        wp.delete('iss_reference_building')
        wp.delete('iss_reference_room')
        wp.delete('user_iss')
      end

      # Получить список работников указанного отдела.
      @users = UserIss
                 .select(:id_tn, :fio)
                 .where(dept: params[:division])

      data = {
        workplaces: @workplaces,
        users: @users
      }

      render json: data, status: 200
    end

    def data_from_audit
      @host = HostIss.get_host(params[:invent_num])

      if @host.nil?
        render json: { full_message: 'Данные по указанному инвентарному номеру не найдены. Проверьте корректность
введенного номера или загрузите файл конфигурации нажав кнопку "Ввод данных вручную".' }, status: 422
        return
      end

      error_message = 'Получить данные автоматически не удалось, вам необходимо ввести их вручную. Для этого вам
 необходимо нажать кнопку "Ввод данных вручную"'

      # В течении 29 секунд пытаться выполнить запрос к Аудиту.
      begin
        Timeout.timeout(29) do
          loop do
            begin
              @audit_data = Audit.get_data(@host['name'])
              break
            rescue Exception
            end
          end
        end
      rescue Timeout::Error
        render json: { full_message: error_message }, status: 422
        return
      end

      # Данных от аудита нет
      if @audit_data.nil?
        render json: { full_message: error_message }, status: 422
        return
      elsif Audit.relevance?(@audit_data)
        # Проверяем актуальность данных по полю last_connection
        render json: @audit_data, status: 200
      else
        render json: { full_message: error_message }, status: 422
      end
    end

    # Создать РМ
    def create_workplace
      unless create_or_get_room
        render json: { full_message: @room.errors.full_messages.join('. ') }, status: 422
        return
      end

      @workplace = Workplace.new(workplace_params)

      # Логирование полученных данных
      logger.info "WORKPLACE: #{@workplace.inspect}".red
      @workplace.inv_items.each_with_index do |item, item_index|
        logger.info "ITEM [#{item_index}]: #{item.inspect}".green

        item.inv_property_values.each_with_index do |val, prop_index|
          logger.info "PROP_VALUE [#{prop_index}]: #{val.inspect}".cyan
        end
      end

      if @workplace.save
        # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например, вызвать
        # find)
        @workplace = transform_workplace(Workplace
                                           .includes(inv_items: [:inv_type, { inv_property_values: :inv_property }])
                                           .find(@workplace.workplace_id))

        unless params[:pc_file] == 'null'
          logger.info 'Получен файл для загрузки'.red
          return false unless upload_file
        end

        render json: { workplace: @workplace, full_message: 'Рабочее место создано.' }, status: :ok
      else
        render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: :unprocessable_entity
      end
    end

    def edit_workplace
      @workplace = Workplace
                     .includes(:iss_reference_room)
                     .find(params[:workplace_id])

      unless @workplace
        render json: { full_message: 'Рабочее место не найдено.' }, status: 404
      end

      @workplace = @workplace.as_json(
        include: {
          iss_reference_room: {},
          inv_items: {
            include: :inv_property_values
          }
        }
      )

      # Преобразование объекта.
      @workplace['location_room_name'] = @workplace['iss_reference_room']['name']
      @workplace['inv_items_attributes'] = @workplace['inv_items']
      @workplace.delete('inv_items')
      @workplace.delete('iss_reference_room')
      @workplace.delete('location_room_id')

      @workplace['inv_items_attributes'].each do |item|
        item['id'] = item['item_id']
        item['inv_property_values_attributes'] = item['inv_property_values']
        item.delete('item_id')
        item.delete('inv_property_values')

        item['inv_property_values_attributes'].each do |prop_val|
          prop_val['id'] = prop_val['property_value_id']
          prop_val.delete('property_value_id')
        end
      end

      render json: @workplace, status: 200
    end

    def update_workplace
      workplace
      if @workplace

        create_or_get_room
        if @workplace.update_attributes(workplace_params)
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = transform_workplace(Workplace
                                             .includes(
                                               :iss_reference_site,
                                               :iss_reference_building,
                                               :iss_reference_room,
                                               inv_items: { inv_property_values: :inv_property }
                                             )
                                             .find(@workplace.workplace_id))

          unless params[:pc_file] == 'null'
            return false unless upload_file
          end

          render json: { workplace: @workplace, full_message: 'Данные о рабочем месте обновлены.' }, status: :ok
        else
          render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
        end
      else
        render json: { full_message: 'Рабочее место не найдено' }, status: 422
      end
    end

    def delete_workplace
      workplace
      if @workplace
        if @workplace.destroy_from_***REMOVED***
          render json: { full_message: 'Рабочее место удалено.' }, status: 200
        else
          render json: { full_message: @workplace.errors.full_messages.join('. ') }, status: 422
        end
      else
        render json: { full_message: 'Рабочее место не найдено' }, status: 422
      end
    end

    def generate_pdf
      @workplace_count = WorkplaceCount
                           .includes(workplaces: [:workplace_type, :user_iss, { inv_items: :inv_type }])
                           .where(division: params[:division])
                           .first

      render pdf: 'test',
             template: 'templates/workplace.haml',
             locals: { workplace_count: @workplace_count },
             encoding: 'UTF-8'
      # disposition: 'attachment'
    end

    def send_pc_script
      send_file(Rails.root.join('public', 'downloads', 'SysInfo.exe'), disposition: 'attachment')
    end

    private

    # Если комната в базе не существует, создать комнату. Если комната в базе существует - получить id комнаты.
    # Возвращает true, если ошибок нет; false - если не удалось создать комнату
    def create_or_get_room
      @room = IssReferenceRoom.find_by(name: params[:workplace][:location_room_name])

      if @room.nil?
        @room = IssReferenceRoom.new(
          building_id: params[:workplace][:location_building_id],
          name: params[:workplace][:location_room_name]
        )

        return false unless @room.save
      end

      params[:workplace].delete :location_room_name
      params[:workplace][:location_room_id] = @room.room_id

      true
    end

    # Сохранить файл в файловой системе.
    def upload_file
      property_value_id = 0
      # Получаем property_value_id, чтобы создать директорию.
      @workplace['inv_items'].each do |item|
        next if InvPropertyValue::PROPERTY_WITH_FILES.none? { |val| val == item['inv_type']['name'] }

        property_value_id = item['inv_property_values'].find do |val|
          val['inv_property']['name'] == 'config_file'
        end['property_value_id']

        break if property_value_id
      end

      unless property_value_id
        render json: { workplace: @workplace, full_message: 'Рабочее место создано, но сохранить файл конфигурации не
удалось. Для загрузки файла свяжитесь с администратором сервиса.' }, status: 200

        return false
      end

      # Путь директории для записи загруженного файла.
      path_to_file = Rails.root.join('public', 'uploads', property_value_id.to_s)

      # Проверить, существует ли директория public/upload/<property_value_id>. Если нет - создать.
      FileUtils.mkdir_p(path_to_file) unless path_to_file.exist?

      # Удалить все существующие файлы из директории.
      Dir.foreach(path_to_file) do |file|
        FileUtils.rm_f("#{path_to_file}/#{file}") if file != '.' && file != '..'
      end

      # Запись файла
      uploaded_io = params[:pc_file]
      File.open("#{path_to_file}/#{uploaded_io.original_filename}", 'w:UTF-8:ASCII-8BIT') do |file|
        file.write(uploaded_io.read)
      end

      true
    rescue Exception => e
      logger.info "Ошибка функции upload_file. #{e}".red
      logger.info 'Описание:'
      e.backtrace.each { |val| logger.info val }

      render json: { workplace: @workplace, full_message: 'Рабочее место создано, но сохранить файл конфигурации не' \
' удалось. Для загрузки файла свяжитесь с администратором сервиса.' }, status: 200

      false
    end

    # Преобразование объекта workplace в специальный вид, чтобы таблица могла отобразить данные.
    def transform_workplace(wp)
      wp = wp.as_json(
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

      wp['short_description'] = wp['workplace_type']['short_description']
      wp['duty'] = wp['user_iss']['duty']
      wp['fio'] = wp['user_iss']['fio_initials']
      wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп. #{wp['iss_reference_building']['name']},
комн. #{wp['iss_reference_room']['name']}"

      wp.delete('iss_reference_site')
      wp.delete('iss_reference_building')
      wp.delete('iss_reference_room')
      wp.delete('user_iss')
      wp.delete('workplace_type')

      wp
    end

    # Проверить SID в таблице user_sessions, чтобы знать, действительно ли пользователь авторизован в ЛК.
    def check_***REMOVED***_authorization
      if params[:sid]
        @user_session = UserSession.find(params[:sid])
        if @user_session.nil?
          render json: { full_message: 'Доступ запрещен' }, status: 403
        else
          data = PHP.unserialize(@user_session.data)
          if data['authed'] && Time.zone.now < (Time.zone.at(@user_session.last_access) + @user_session.timeout)
            @user = User.find_by(tn: 999_999)
            if @user.nil?
              render json: { full_message: 'Ошибка доступа. Обратитесь к администратору' }, status: 403
            else
              sign_in :user, @user
              @user_iss = UserIss.find_by(tn: data['user_id'])
              if @user_iss
                session[:id_tn] = @user_iss.id_tn
              else
                render json: { full_message: 'Ошибка доступа. Обратитесь к администратору' }, status: 403
              end
            end
          else
            render json: { full_message: 'Доступ запрещен' }, status: 403
          end
        end
      else
        render json: { full_message: 'Доступ запрещен' }, status: 403
      end
    end

    # Проверить, есть ли у пользователя доступ на создание/редактирование/удаление рабочих мест указанного отдела.
    def check_workplace_count_access
      params[:workplace] = JSON.parse(params[:workplace])
      unless params[:workplace]
        render json: { full_message: 'Доступ запрещен' }, status: 403
        return
      end

      workplace_count
      if @workplace_count
        unless @workplace_count.workplace_responsibles.any? { |resp| resp.id_tn == session[:id_tn] }
          render json: { full_message: 'Доступ запрещен' }, status: 403
        end
      end
    end

    # Проверить, прошло ли разрешенное время редактирования для указанного отдела.
    def check_timeout
      # Для случаев, когда workplace_id существует (например, редактирование или удаление записи)
      if params[:workplace_id]
        workplace
        unless time_not_passed?(@workplace.workplace_count.time_start, @workplace.workplace_count.time_end)
          render json: { full_message: "Время для работы с отделом #{@workplace.workplace_count.division} истекло" },
                 status: 403

          return false
        end
        # Для случаев, когда workplace_id не существует (создается новая запись), но задан workplace_count_id
      elsif params[:workplace] && params[:workplace][:workplace_count_id]
        workplace_count

        unless time_not_passed?(@workplace_count.time_start, @workplace_count.time_end)
          render json: { full_message: "Время для работы с отделом #{@workplace_count.division} истекло" }, status: 403

          return false
        end
        # Для случая, когда задан отдел, запрос отправлен для генерации PDF. Здесь, наоборот, необходимо разрешить
        # доступ, только если прошло разрешенное время редактирования.
      elsif params[:division]
=begin
      @workplace_count = WorkplaceCount.find_by(division: params[:division])

      if (time_not_passed?(@workplace_count.time_start, @workplace_count.time_end))
        render json: { full_message: "Время для работы с отделом #{@workplace_count.division} не истекло.  Экспорт в PDF
файл станет доступен #{@workplace_count.time_end + 1.day}" }, status: 403

        return false
      end
=end
      else
        render json: { full_message: 'Доступ запрещен, так как не удается определить, к какому отделу относится' \
' запрашиваемая операция. Обратитесь к администратору' }, status: 403

        false
      end
    end

    # Проверка, входит ли текущее время в указанный интервал (true - если входит).
    def time_not_passed?(time_start, time_end)
      Date.today >= time_start && Date.today <= time_end
    end

    # Создать переменную @workplace_count, если она не существует.
    def workplace_count
      @workplace_count = WorkplaceCount.find(params[:workplace][:workplace_count_id]) unless @workplace_count
    end

    # Создать переменную @workplace, если она не существует.
    def workplace
      @workplace = Workplace.find(params[:workplace_id]) unless @workplace
    end

    def workplace_params
      params.require(:workplace).permit(
        :workplace_count_id,
        :workplace_type_id,
        :workplace_specialization_id,
        :id_tn,
        :location_site_id,
        :location_building_id,
        :location_room_name,
        :location_room_id,
        :comment,
        :status,
        inv_items_attributes: [
          :id,
          :parent_id,
          :type_id,
          :model_id,
          :item_model,
          :workplace_id,
          :location,
          :invent_num,
          :_destroy,
          inv_property_values_attributes: %i[
            id
            property_id
            item_id
            property_list_id
            value
            _destroy
          ]
        ]
      )
    end
  end
end
