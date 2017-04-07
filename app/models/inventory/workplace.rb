module Inventory
  class Workplace < Invent
    self.primary_key  = :workplace_id
    self.table_name   = :invent_workplace

    has_many    :inv_items
    belongs_to  :workplace_type
    belongs_to  :workplace_specialization
    belongs_to  :workplace_count
    belongs_to  :user_iss, foreign_key: 'id_tn', optional: true

    before_validation :check_id_tn

    validates :id_tn, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не указано
(или введено с ошибкой). Проверьте корректность введенного ФИО' }, unless: -> { self.errors.any? }
    validates :workplace_count_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не
указан' }
    validates :workplace_type_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не
выбран' }
    validates :workplace_specialization_id, presence: true, numericality: { greater_than: 0, only_integer: true,
                                                                            message: 'не выбрано' }
    validates :location, presence: true
    validate  :check_workplace_conditions, unless: -> { self.workplace_type_id == -1  }
    # validate  :at_least_one_pc
    # validate  :compare_responsibles

    accepts_nested_attributes_for :inv_items, allow_destroy: true, reject_if: proc{ |attr| attr['type_id'].to_i.zero? }

    enum status: { 'Утверждено': 0, 'В ожидании проверки': 1, 'Отклонено': 2 }

    # Удалить РМ, связанные экземпляры техники, значения их свойств, а также загруженные файлы.
    def destroy_from_***REMOVED***
      Workplace.transaction do
        begin
          self.destroy if self.inv_items.destroy_all
        rescue ActiveRecord::RecordNotDestroyed => e
          self.errors.add(:base, 'Не удалось удалить запись. Обратитесь к администратору.')
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
      if id_tn
        self.errors.add(:base, 'Проверьте корректность введенного ФИО') unless UserIss.find_by(id_tn: self.id_tn.to_i)
      else
        self.id_tn = -1 unless id_tn
      end
    end

    # Проверка условий, которые должны выполняться при создании/редактировании рабочих мест.
    def check_workplace_conditions
      @types = InvType.all

      case self.workplace_type.name
        when 'rm_pk'
          # Для стационарного РМ.
          # Должен содержать один системный блок/моноблок + минимум один монитор. Создавать планшет, ноутбук, все
          # виды печатающих устройств с сетевым типом подключением для стационарного РМ запрещено.

          # Число системных блоков.
          pc_count      = 0
          # Число моноблоков.
          allin1_count  = 0
          # Число мониторов.
          monitor_count = 0
          # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
          net_printer = false

          # Массив типов устройств ПК, создание которых возможно для данного типа РМ.
          tmp_pc_types    = @types.select{ |type| %w{ pc allin1 }.include?(type['name']) }
          # Массив типов печатающих устройств.
          tmp_print_types = @types.select{ |type| %w{ printer plotter scanner mfu copier print_system }.include?(type['name']) }
          # Объект свойства "Тип подключения".
          @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')

          self.inv_items.each do |item|
            next if item._destroy

            pc_count      += 1 if item.type_id == @types.find{ |type| type['name'] == 'pc' }.type_id
            allin1_count  += 1 if item.type_id == @types.find{ |type| type['name'] == 'allin1' }.type_id

            # pc_count      += 1 if tmp_pc_types.find{ |type| type['type_id'] == item.type_id }
            monitor_count += 1 if item.type_id == @types.find{ |type| type['name'] == 'monitor' }.type_id

            # Проверка, пытается ли пользователь создать сетевое печатающее устройство.
            unless item.model_id == -1
              if tmp_print_types.find{ |type| type['type_id'] == item.type_id }
                net_printer = true if item.inv_property_values.find{ |val| val['property_id'] == @property.property_id
                  }['property_list_id'] == @property.inv_property_lists.find{ |list| list['value'] == 'network'
                  }['property_list_id']
              end
            end
          end

          errors.add(:base, 'Неправильный состав стационарного рабочего места') if (pc_count + allin1_count) > 1 ||
            (pc_count.zero? && allin1_count.zero?) || (monitor_count.zero? && allin1_count.zero?) || net_printer

          errors.add(:base, 'На одном стационарном рабочем месте может находиться только один системный блок или
моноблок.') if (pc_count + allin1_count) > 1
          errors.add(:base, 'Необходимо создать хотя бы один системный блок или моноблок') if pc_count.zero? &&
            allin1_count.zero?
          errors.add(:base, 'Для системного блока необходимо создать хотя бы один монитор') if monitor_count.zero? &&
            allin1_count.zero?
          errors.add(:base, 'Для стационарного рабочего места запрещено создавать печатающие устройства с сетевым типом
подключения, измените тип подключения или тип рабочего места на "Рабочее место печати".') if net_printer

        when 'rm_mob'
          # Для мобильного РМ.
          # Должен содержать только один ноутбук/планшет (остальное запрещено). Создавать другие типы оборудования
          # для мобильного РМ запрещено.

          # Общее число техники.
          count       = 0
          # Число ноутбуков/планшетов.
          note_count  = 0
          # Массив типов устройств, создание которых возможно для данного типа РМ.
          tmp_types   = @types.select{ |type| %w{ tablet notebook }.include? type['name'] }
          self.inv_items.each do |item|
            next if item._destroy

            count       += 1
            note_count  += 1 if tmp_types.find{ |type| type['type_id'] == item.type_id }
          end

          errors.add(:base, 'Неправильный состав мобильного рабочего места') if count > 1 || count != 0 && count !=
            note_count
          errors.add(:base, 'На одном мобильном рабочем месте может находиться только один планшет или ноутбук') if
            count > 1
          errors.add(:base, 'Мобильное рабочее место может включать только ноутбук или планшет.') if count != 0 &&
            count != note_count

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

          # Общее число техники
          count               = 0
          # Число печатающих устройств с сетевым подключением
          net_printer_count   = 0
          # Число печатающих устройств с локальным подключением
          loc_printer_count   = 0
          # Число 3d принтеров
          _3d_printer_count   = 0
          # Число принт-серверов
          print_server_count  = 0
          # Число печатных машин
          print_system_count  = 0
          # Число системных блоков/моноблоков.
          pc_count            = 0
          # Число мониторов.
          monitor_count       = 0

          # Массив типов печатающих устройств (сетевых).
          tmp_print_types = @types.select{ |type| %w{ printer plotter scanner mfu }.include?(type['name']) }
          # Массив типов устройств ПК, создание которых возможно для данного типа РМ.
          tmp_pc_types    = @types.select{ |type| %w{ pc allin1 }.include?(type['name']) }
          # Объект свойства "Тип подключения".
          @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')

          self.inv_items.each do |item|
            next if item._destroy

            count += 1

            unless item.model_id == -1
              net_printer_count += 1 if tmp_print_types.find{ |type| type['type_id'] == item.type_id } && item
                .inv_property_values.find{ |val| val['property_id'] == @property.property_id }['property_list_id'] ==
                @property.inv_property_lists.find{ |list| list['value'] == 'network' }['property_list_id']

              loc_printer_count += 1 if tmp_print_types.find{ |type| type['type_id'] == item.type_id } && item
                .inv_property_values.find{ |val| val['property_id'] == @property.property_id }['property_list_id'] ==
                @property.inv_property_lists.find{ |list| list['value'] == 'local' }['property_list_id']
            end

            _3d_printer_count   += 1 if item.type_id == @types.find{ |type| type['name'] == '3d_printer' }.type_id
            print_server_count  += 1 if item.type_id == @types.find{ |type| type['name'] == 'print_server' }.type_id
            print_system_count  += 1 if item.type_id == @types.find{ |type| type['name'] == 'print_system' }.type_id
            pc_count            += 1 if tmp_pc_types.find{ |type| type['type_id'] == item.type_id }
            monitor_count       += 1 if item.type_id == @types.find{ |type| type['name'] == 'monitor' }.type_id
          end

          errors.add(:base, 'Неправильный состав рабочего места печати') if
            net_printer_count > 1 ||
            _3d_printer_count > 1 ||
            print_system_count > 1 ||
            print_system_count == 1 && (print_system_count + pc_count + monitor_count) != count ||
            print_server_count > 1 ||
            print_server_count == 1 && (print_server_count + loc_printer_count) != count ||
            (net_printer_count + _3d_printer_count + print_server_count + print_system_count) > 1 ||
            count != 0 && (net_printer_count + _3d_printer_count + print_server_count + print_system_count) == 0 && loc_printer_count != 0

          if net_printer_count > 1
            errors.add(:base, 'На одном рабочем месте печати может находиться только один принтер, подключенный к
локальной сети')
          elsif net_printer_count == 1 && net_printer_count != count
            errors.add(:base, 'Совместно с принтером, подключенным к локальной сети, нельзя создавать какое-либо
устройство')
          end

          if _3d_printer_count > 1
            errors.add(:base, 'На одном рабочем месте печати может находиться только один 3D-принтер')
          elsif _3d_printer_count == 1 && count != _3d_printer_count
            errors.add(:base, 'Совместно с 3D-принтером нельзя создать какое-либо устройство')
          end

          if print_system_count > 1
            errors.add(:base, 'На одном рабочем месте печати может находиться только одна печатная машина')
          elsif print_system_count == 1 && (print_system_count + pc_count + monitor_count) != count
            errors.add(:base, 'Совместно с печатной машиной можно создать только подключенный к ней ПК (системный
блок (или моноблок) и монитор)')
          end

          errors.add(:base, 'Совместно с печатной машиной можно создать только один системный блок или моноблок.') if
            pc_count > 1

          if print_server_count > 1
            errors.add(:base, 'На одном рабочем месте печати может находиться только один принт-сервер')
          elsif print_server_count == 1 && (print_server_count + loc_printer_count) != count
            errors.add(:base, 'Совместно с принт-сервером на рабочем месте печати может находиться только печатающие
устройства с локальным подключением')
          end

          errors.add(:base, 'В состав рабочего места печати может входить только одно печатающее устройство.') if
            (net_printer_count + _3d_printer_count + print_server_count + print_system_count) > 1
          errors.add(:base, 'В состав рабочего места печати необходимо добавить хотя бы одно печатающее устройство.') if
            count != 0 && (net_printer_count + _3d_printer_count + print_server_count + print_system_count) == 0

        when 'rm_server'
          # Для сервера условия такие же, как для стационарного РМ.
          # Должен быть создан системный блок (+ возможно монитор). Создавать планшет, ноутбук, все виды печатающих
          # устройств с сетевым типом подключением для серверного РМ запрещено.

          # Число системных блоков/моноблоков.
          pc_count      = 0
          # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
          net_printer = false

          # Массив типов устройств ПК, создание которых возможно для данного типа РМ.
          tmp_pc_types    = @types.select{ |type| %w{ pc allin1 }.include?(type['name']) }
          # Массив типов печатающих устройств.
          tmp_print_types = @types.select{ |type| %w{ printer plotter scanner mfu copier print_system }.include?(type['name']) }
          # Объект свойства "Тип подключения".
          @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')

          self.inv_items.each do |item|
            next if item._destroy

            pc_count      += 1 if tmp_pc_types.find{ |type| type['type_id'] == item.type_id }

            # Проверка, если пользователь пытается создать печатающее устройство.
            unless item.model_id == -1
              if tmp_print_types.find{ |type| type['type_id'] == item.type_id }
                net_printer = true if item.inv_property_values.find{ |val| val['property_id'] == @property.property_id
                }['property_list_id'] == @property.inv_property_lists.find{ |list| list['value'] == 'network'
                }['property_list_id']
              end
            end
          end

          errors.add(:base, 'Неправильный состав серверного рабочего места') if pc_count > 1 || pc_count.zero? ||
            net_printer
          errors.add(:base, 'На одном серверном рабочем месте может находиться только один системный блок или
моноблок.') if pc_count > 1
          errors.add(:base, 'Необходимо создать хотя бы один системный блок/моноблок') if pc_count.zero?
          errors.add(:base, 'Для серверного рабочего места запрещено создавать печатающие устройства с сетевым типом
подключения, измените тип подключения или тип рабочего места на "Рабочее место печати".') if net_printer
      end
    end

=begin
    # Проверка на наличие системного блока/моноблока и монитора для стационарного ПК.
    def at_least_one_pc
      pc_count  = 0
      monitor   = 0

      @pcs      = InvType.where(name: InvPropertyValue::PROPERTY_WITH_FILES)
      @monitor  = InvType.find_by(name: 'monitor')

      # inv_items.each { |item| type_count += 1 if item.type_id == @type.type_id }
      self.inv_items.each do |item|
        pc_count  += 1 if @pcs.find{ |pc| pc['type_id'] == item.type_id }
        # if item.type_id == @type.type_id
        monitor   += 1 if item.type_id == @monitor.type_id
      end

      errors.add(:base, 'На одном рабочем месте может находиться только один системный блок.') if pc_count > 1
      errors.add(:base, 'Необходимо создать системный блок') if pc_count.zero?
      errors.add(:base, 'Необходимо создать хотя бы один монитор') if monitor.zero?
    end
=end

    # Проверка, совпадает табельный номер ответственного за РМ с ответственным за системный блок.
    def compare_responsibles
      get_type

      inv_items.each do |item|
        if item.type_id == @type.type_id
          # Получаем данные о системном блоке
          @host = HostIss.get_host(item.invent_num)
          if @host
            begin
              @user = UserIss.find(self.id_tn)

              errors.add(:base, 'Табельный номер ответственного за рабочее место не совпадает с табельным номером
ответственного за системный блок.') unless @host['tn'] == @user.tn
            rescue ActiveRecord::RecordNotFound
              errors.add(:id_tn, 'не найден в базе данных отдела кадров, обратитесь к администратору')
            end
          end

          break
        end
      end
    end

    # Создать переменную @type (класс InvType), если она не существует.
    def get_type
      @type = InvType.find_by(name: 'pc') unless @type
    end
  end
end