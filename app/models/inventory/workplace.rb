module Inventory
  class Workplace < Invent
    self.primary_key = :workplace_id
    self.table_name = :invent_workplace

    has_many :inv_items
    belongs_to :workplace_type
    belongs_to :workplace_specialization
    belongs_to :workplace_count
    belongs_to :user_iss, foreign_key: 'id_tn', optional: true
    belongs_to :iss_reference_site, foreign_key: 'location_site_id'
    belongs_to :iss_reference_building, foreign_key: 'location_building_id'
    belongs_to :iss_reference_room, foreign_key: 'location_room_id'

    before_validation :check_id_tn

    validates :id_tn,
              presence: true,
              numericality: { greater_than: 0, only_integer: true, message: 'введено с ошибкой. Проверьте' \
' корректность введенного ФИО' },
              unless: -> { errors.any? }
    validates :workplace_count_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true, message: 'не указан' }
    validates :workplace_type_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true, message: 'не выбран' }
    validates :workplace_specialization_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true, message: 'не выбрано' }
    validates :location_site_id,
              presence: { message: 'не указана' },
              numericality: { greater_than: 0, only_integer: true, message: 'не выбрана' }
    validates :location_building_id,
              presence: { message: 'не указан' },
              numericality: { greater_than: 0, only_integer: true, message: 'не выбран' }
    validates :location_room_id,
              presence: { message: 'не указана' },
              numericality: { greater_than: 0, only_integer: true, message: 'не указана' }
    validate :check_workplace_conditions, unless: -> { workplace_type_id == -1 }
    # validate  :compare_responsibles

    accepts_nested_attributes_for :inv_items, allow_destroy: true, reject_if: proc { |attr| attr['type_id'].to_i.zero? }

    enum status: { 'Утверждено': 0, 'В ожидании проверки': 1, 'Отклонено': 2 }

    # Удалить РМ, связанные экземпляры техники, значения их свойств, а также загруженные файлы.
    def destroy_from_***REMOVED***
      Workplace.transaction do
        begin
          destroy if inv_items.destroy_all
        rescue ActiveRecord::RecordNotDestroyed
          errors.add(:base, 'Не удалось удалить запись. Обратитесь к администратору.')
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    # Установить отрицательный id_tn, если он отсутствует. Это необходимо, чтобы пользователю выдалось корректное
    # описание ошибки, если он ввел неверное ФИО. Без этой валидации если пользователь введет ФИО с ошибкой, id_tn
    # отправится пустым и пользовтелю будет сказано о том, что необходимо заполнить ФИО. Но ФИО будет заполнено в поле,
    # что может привести пользователя в тупик.
    def check_id_tn
      if id_tn.to_i.zero? || UserIss.find_by(id_tn: id_tn.to_i).nil?
        errors.add(:base, 'Проверьте корректность введенного ФИО')
      end
    end

    # Проверка условий, которые должны выполняться при создании/редактировании рабочих мест.
    def check_workplace_conditions
      return unless workplace_type

      @types = InvType.all
      # Объект вида { type: count }, где:
      # type  - имя типа оборудования
      # count - количество оборудования типа type, которое пользователь пытается создать.
      count_all_types = {}
      # Общее число создаваемой техники
      total_count = 0

      # Заполняем объект count_all_types
      @types.each do |type|
        count = inv_items.select do |item|
          next if item._destroy

          item.type_id == type.type_id
        end.length

        count_all_types[type.name] = count
        total_count += count
      end

      case workplace_type.name
      when 'rm_pk'
        # Для стационарного РМ.
        # Должен содержать один системный блок/моноблок + минимум один монитор. Создавать планшет, ноутбук, все
        # виды печатающих устройств с сетевым типом подключением для стационарного РМ запрещено.

        # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
        # net_printer = false
        net_printer = check_net_printer

        if (count_all_types['pc'] + count_all_types['allin1']) > 1 ||
           (count_all_types['pc'].zero? && count_all_types['allin1'].zero?) ||
           (count_all_types['notebook'] + count_all_types['tablet']) >= 1 ||
           (count_all_types['monitor'].zero? && count_all_types['allin1'].zero?) ||
           net_printer
          errors.add(:base, 'Неправильный состав стационарного рабочего места')
        end

        if (count_all_types['pc'] + count_all_types['allin1']) > 1
          errors.add(:base, 'На одном стационарном рабочем месте может находиться только один системный блок или' \
' моноблок.')
        end
        if count_all_types['pc'].zero? && count_all_types['allin1'].zero?
          errors.add(:base, 'Необходимо создать хотя бы один системный блок или моноблок')
        end
        if (count_all_types['notebook'] + count_all_types['tablet']) >= 1
          errors.add(:base, 'На стационарном рабочем месте запрещено создавать ноутбук или планшет (их можно создать' \
' только на мобильном рабочем месте).')
        end
        if count_all_types['monitor'].zero? && count_all_types['allin1'].zero?
          errors.add(:base, 'Для системного блока необходимо создать хотя бы один монитор')
        end
        if net_printer
          errors.add(:base, 'Для стационарного рабочего места запрещено создавать печатающие устройства с сетевым' \
' типом подключения, измените тип подключения или тип рабочего места на "Рабочее место печати".')
        end

      when 'rm_mob'
        # Для мобильного РМ.
        # Должен содержать только один ноутбук/планшет (остальное запрещено). Создавать другие типы оборудования
        # для мобильного РМ запрещено.

        if total_count > 1 && (count_all_types['notebook'] + count_all_types['tablet']) == total_count ||
           total_count != 0 && total_count != (count_all_types['notebook'] + count_all_types['tablet'])
          errors.add(:base, 'Неправильный состав мобильного рабочего места')
        end
        if total_count > 1 && (count_all_types['notebook'] + count_all_types['tablet']) == total_count
          errors.add(:base, 'На одном мобильном рабочем месте может находиться только один планшет или ноутбук')
        end
        if total_count != 0 && total_count != (count_all_types['notebook'] + count_all_types['tablet'])
          errors.add(:base, 'Мобильное рабочее место может включать только ноутбук или планшет.')
        end

      when 'rm_net_print'
        # Для РМ печати.
        # Должен содержать один из следующих типов:
        #   - принтер с типом подключения "Сетевое"
        #   - плоттер с типом подключения "Сетевое"
        #   - сканер с типом подключения "Сетевое"
        #   - МФУ с типом подключения "Сетевое"
        #   - копир. аппарат с типом подключения "Сетевое"
        #   - принт-сервер + минимум один принтер с локальным подключением.
        #   - 3D-принтер
        #   - печатная машина + возможен один ПК (системный блок + минимум один монитор)
        # Создавать другие типы оборудования для РМ печати запрещено.
        # Число печатающих устройств с сетевым подключением
        net_printer_count = 0
        # Число печатающих устройств с локальным подключением
        loc_printer_count = 0
        # Объект свойства "Тип подключения".
        @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')
        # property_list_id со значением 'network' свойства connection_type из объекта @property.
        net_prop_list_id = @property.inv_property_lists.find { |list| list['value'] == 'network' }['property_list_id']
        # property_list_id со значением 'local' свойства connection_type из объекта @property.
        loc_prop_list_id = @property.inv_property_lists.find { |list| list['value'] == 'local' }['property_list_id']
        # Массив объектов с именами заданным в InvItem::ALL_PRINT_TYPES.
        all_print_objects = @types.select do |type_obj|
          InvItem::ALL_PRINT_TYPES.find { |type_name| type_obj['name'] == type_name }
        end

        inv_items.each do |item|
          next if item._destroy || item.model_id == -1

          # InvType, у которого type_id совпадает с одним из all_print_objects
          tmp_inv_type = all_print_objects.find { |type| type['type_id'] == item.type_id }
          next unless tmp_inv_type

          # property_list_id свойства connection_type из полученных данных.
          item_prop_list_id = item.inv_property_values.find do |val|
            val['property_id'] == @property.property_id
          end['property_list_id']

          # Проверка, пытается ли пользователь создать сетевое печатающее устройство.
          if tmp_inv_type && item_prop_list_id == net_prop_list_id
            net_printer_count += 1
          elsif tmp_inv_type && item_prop_list_id == loc_prop_list_id
            loc_printer_count += 1
          end
        end

        if net_printer_count > 1 ||
           net_printer_count == 1 && net_printer_count != total_count ||
           count_all_types['3d_printer'] > 1 ||
           count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer'] ||
           count_all_types['print_server'] > 1 ||
           count_all_types['print_server'] == 1 &&
           (count_all_types['print_server'] + loc_printer_count) != total_count ||
           total_count != 0 && (net_printer_count + count_all_types['3d_printer'] + count_all_types['print_server'])
           .zero?
          errors.add(:base, 'Неправильный состав рабочего места печати')
        end

        if net_printer_count > 1
          errors.add(:base, 'На одном рабочем месте печати может находиться только одно печатающее устройство,' \
' подключенное к локальной сети')
        elsif net_printer_count == 1 && net_printer_count != total_count
          errors.add(:base, 'Совместно с печатающим устройством, подключенным к локальной сети, нельзя создавать' \
' какое-либо устройство')
        end

        if count_all_types['3d_printer'] > 1
          errors.add(:base, 'На одном рабочем месте печати может находиться только один 3D-принтер')
        elsif count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer']
          errors.add(:base, 'Совместно с 3D-принтером нельзя создать какое-либо устройство')
        end

        if count_all_types['print_server'] > 1
          errors.add(:base, 'На одном рабочем месте печати может находиться только один принт-сервер')
        elsif count_all_types['print_server'] == 1 &&
              (count_all_types['print_server'] + loc_printer_count) != total_count
          errors.add(:base, 'Совместно с принт-сервером на рабочем месте печати может находиться только печатающие'\
' устройства с локальным подключением')
        end

        if total_count != 0 &&
           (net_printer_count + count_all_types['3d_printer'] + count_all_types['print_server']).zero?
          errors.add(:base, 'В состав рабочего места печати необходимо добавить хотя бы одно печатающее устройство,' \
' подключенное по сети, либо через принт-сервер.')
        end

      when 'rm_server'
        # Для сервера условия такие же, как для стационарного РМ (только не требуется наличие монитора).
        # Должен быть создан системный блок (+ возможно монитор). Создавать планшет, ноутбук, все виды печатающих
        # устройств с сетевым типом подключением для серверного РМ запрещено.

        # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
        # net_printer = false
        net_printer = check_net_printer

        if (count_all_types['pc'] + count_all_types['allin1']) > 1 ||
           (count_all_types['pc'].zero? && count_all_types['allin1'].zero?) ||
           (count_all_types['notebook'] + count_all_types['tablet']) >= 1 ||
           net_printer
          errors.add(:base, 'Неправильный состав серверного рабочего места')
        end

        if (count_all_types['pc'] + count_all_types['allin1']) > 1
          errors.add(:base, 'На одном серверном рабочем месте может находиться только один системный блок или' \
' моноблок.')
        end
        if count_all_types['pc'].zero? && count_all_types['allin1'].zero?
          errors.add(:base, 'Необходимо создать хотя бы один системный блок или моноблок')
        end
        if (count_all_types['notebook'] + count_all_types['tablet']) >= 1
          errors.add(:base, 'На серверном рабочем месте запрещено создавать ноутбук или планшет (их можно создать' \
' только на мобильном рабочем месте).')
        end
        if net_printer
          errors.add(:base, 'Для серверного рабочего места запрещено создавать печатающие устройства с сетевым типом' \
' подключения, измените тип подключения или тип рабочего места на "Рабочее место печати".')
        end
      end
    end

    # Проверка, пытается ли пользователь создать сетевой принтер.
    def check_net_printer
      # Объект свойства "Тип подключения".
      @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')
      # property_list_id со значением 'network' свойства connection_type из объекта @property.
      network_prop_list_id = @property.inv_property_lists.find do |list|
        list['value'] == 'network'
      end['property_list_id']
      # Массив объектов с именами заданным в InvItem::ALL_PRINT_TYPES.
      all_print_objects = @types.select do |type_obj|
        InvItem::ALL_PRINT_TYPES.find { |type_name| type_obj['name'] == type_name }
      end

      inv_items.each do |item|
        next if item._destroy || item.model_id == -1
        next unless all_print_objects.find { |type| type['type_id'] == item.type_id }

        # property_list_id свойства connection_type из полученных данных.
        item_prop_list_id = item.inv_property_values.find do |val|
          val['property_id'] == @property.property_id
        end['property_list_id']

        # Проверка, пытается ли пользователь создать сетевое печатающее устройство.
        return true if item_prop_list_id == network_prop_list_id
      end

      false
    end

    # Проверка, совпадает табельный номер ответственного за РМ с ответственным за системный блок.
    def compare_responsibles
      inv_type

      inv_items.each do |item|
        next unless item.type_id == @type.type_id

        # Получаем данные о системном блоке
        @host = HostIss.get_host(item.invent_num)
        if @host
          begin
            @user = UserIss.find(id_tn)

            unless @host['tn'] == @user.tn
              errors.add(:base, 'Табельный номер ответственного за рабочее место не совпадает с табельным номером' \
' ответственного за системный блок.')
            end
          rescue ActiveRecord::RecordNotFound
            errors.add(:id_tn, 'не найден в базе данных отдела кадров, обратитесь к администратору')
          end
        end

        break
      end
    end

    # Создать переменную @type (класс InvType), если она не существует.
    def inv_type
      @type = InvType.find_by(name: 'pc') unless @type
    end
  end
end
