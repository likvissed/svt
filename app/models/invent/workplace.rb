module Invent
  class Workplace < BaseInvent
    self.primary_key = :workplace_id
    self.table_name = "#{table_name_prefix}workplace"

    has_many :inv_items, inverse_of: :workplace, dependent: :nullify
    belongs_to :workplace_type
    belongs_to :workplace_specialization
    belongs_to :workplace_count
    belongs_to :user_iss, foreign_key: 'id_tn', optional: true
    belongs_to :iss_reference_site, foreign_key: 'location_site_id'
    belongs_to :iss_reference_building, foreign_key: 'location_building_id'
    belongs_to :iss_reference_room, foreign_key: 'location_room_id'

    validates :id_tn,
              presence: true,
              numericality: { only_integer: true },
              reduce: true, unless: :status_freezed?
    validates :id_tn, user_iss_by_id_tn: true, unless: -> { errors.any? || status_freezed? }
    validates :workplace_count_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true }
    validates :workplace_type_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true }
    validates :workplace_specialization_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true }
    validates :location_site_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true }
    validates :location_building_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true }
    validates :location_room_id,
              presence: true,
              numericality: { greater_than: 0, only_integer: true }
    validate :check_workplace_conditions, if: -> { workplace_type_id != -1 && enabled_filters }

    # Для тестов (от имени пользователя заполняется поле "Комната")
    attr_accessor :location_room_name, :division
    # Поле указывает, нужно ли использовать валидаторы при создании/редактировании текущей модели
    attr_accessor :enabled_filters

    delegate :division, to: :workplace_count

    accepts_nested_attributes_for :inv_items, reject_if: proc { |attr| attr['type_id'].to_i.zero? }

    enum status: { confirmed: 0, pending_verification: 1, disapproved: 2, freezed: 3 }

    # Удалить РМ, связанные экземпляры техники, значения их свойств, а также загруженные файлы.
    def destroy_from_***REMOVED***
      Workplace.transaction do
        begin
          destroy if inv_items.destroy_all
        rescue ActiveRecord::RecordNotDestroyed
          errors.add(:base, :cant_destroy_items)
          raise ActiveRecord::Rollback
        end
      end
    end

    def status_freezed?
      status == 'freezed'
    end

    private

    # Проверка условий, которые должны выполняться при создании/редактировании рабочих мест.
    def check_workplace_conditions
      return unless workplace_type

      @types = InvType.all
      # count_all_types - объект вида { type: count }, где:
      #   type  - имя типа оборудования
      #   count - количество оборудования типа type, которое пользователь пытается создать.
      # total_count - общее число создаваемой техники
      count_all_types, total_count = set_count_all_types

      case workplace_type.name
      when 'rm_pk'
        rm_pk_verification(count_all_types)
      when 'rm_mob'
        rm_mob_verification(count_all_types, total_count)
      when 'rm_net_print'
        rm_net_print_verification(count_all_types, total_count)
      when 'rm_server'
        rm_server_verification(count_all_types)
      else
        errors.add(:base, 'Неизвестнй тип рабочего места')
      end
    end

    # Заполнить объект count_all_types и посчитать total_count.
    def set_count_all_types
      count_all_types = {}
      total_count = 0

      @types.each do |type|
        count = inv_items.select do |item|
          # next if item._destroy
          # Не считать технику, если она была удалена из списка. После удаления из списка, техника не будет удалена из
          # БД, удалится только связь с текущим РМ.
          next if item.item_id && item.workplace_id.nil?

          item.type_id == type.type_id
        end.length

        count_all_types[type.name] = count
        total_count += count
      end

      [count_all_types, total_count]
    end

    # Для стационарного РМ.
    # Должен содержать один системный блок/моноблок + минимум один монитор. Создавать планшет, ноутбук, все
    # виды печатающих устройств с сетевым типом подключением для стационарного РМ запрещено.
    def rm_pk_verification(count_all_types)
      # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
      # net_printer = false
      net_printer = check_net_printer

      if (count_all_types['pc'] + count_all_types['allin1']) > 1 ||
         (count_all_types['pc'].zero? && count_all_types['allin1'].zero?) ||
         (count_all_types['notebook'] + count_all_types['tablet']) >= 1 ||
         (count_all_types['monitor'].zero? && count_all_types['allin1'].zero?) ||
         net_printer
        errors.add(:base, :wrong_rm_pk_composition)
      end

      if (count_all_types['pc'] + count_all_types['allin1']) > 1
        errors.add(:base, :rm_pk_only_one_pc_or_allin1)
      end
      if (count_all_types['pc'] + count_all_types['allin1']).zero?
        errors.add(:base, :rm_pk_at_least_one_pc_or_allin1)
      end
      if (count_all_types['notebook'] + count_all_types['tablet']) >= 1
        errors.add(:base, :rm_pk_forbid_notebook_and_tablet)
      end
      if count_all_types['monitor'].zero? && count_all_types['allin1'].zero?
        errors.add(:base, :rm_pk_at_least_one_monitor)
      end
      errors.add(:base, :rm_pk_forbid_net_printer) if net_printer
    end

    # Для мобильного РМ.
    # Должен содержать только один ноутбук/планшет (остальное запрещено). Создавать другие типы оборудования
    # для мобильного РМ запрещено.
    def rm_mob_verification(count_all_types, total_count)
      if (count_all_types['notebook'] + count_all_types['tablet']).zero? ||
         total_count != 0 && total_count != (count_all_types['notebook'] + count_all_types['tablet']) ||
         total_count > 1 && (count_all_types['notebook'] + count_all_types['tablet']) == total_count
        errors.add(:base, :wrong_rm_mob_composition)
      end

      if (count_all_types['notebook'] + count_all_types['tablet']).zero?
        errors.add(:base, :at_least_one_notebook_or_tablet)
      end
      if total_count != 0 && total_count != (count_all_types['notebook'] + count_all_types['tablet'])
        errors.add(:base, :only_notebook_or_tablet)
      end
      if total_count > 1 && (count_all_types['notebook'] + count_all_types['tablet']) == total_count
        errors.add(:base, :only_one_notebook_or_tablet)
      end
    end

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
    def rm_net_print_verification(count_all_types, total_count)
      @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')
      printer_count = set_printer_count

      if (printer_count[:net] + count_all_types['3d_printer'] + count_all_types['print_server']).zero? ||
         printer_count[:net] > 1 ||
         printer_count[:net] == 1 && printer_count[:net] != total_count ||
         count_all_types['3d_printer'] > 1 ||
         count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer'] ||
         count_all_types['print_server'] > 1 ||
         count_all_types['print_server'] == 1 && (count_all_types['print_server'] + printer_count[:loc]) != total_count ||
         total_count != 0 && (printer_count[:net] + count_all_types['3d_printer'] + count_all_types['print_server']).zero?
        errors.add(:base, :wrong_rm_net_print_composition)
      end

      if (printer_count[:net] + count_all_types['3d_printer'] + count_all_types['print_server']).zero?
        errors.add(:base, :at_least_one_print)
      end

      if printer_count[:net] > 1
        errors.add(:base, :only_one_net_print)
      elsif printer_count[:net] == 1 && printer_count[:net] != total_count
        errors.add(:base, :net_print_without_any_devices)
      end

      if count_all_types['3d_printer'] > 1
        errors.add(:base, :only_one_3d_printer)
      elsif count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer']
        errors.add(:base, :_3d_printer_without_any_devices)
      end

      if count_all_types['print_server'] > 1
        errors.add(:base, :only_one_print_server)
      elsif count_all_types['print_server'] == 1 && (count_all_types['print_server'] + printer_count[:loc]) != total_count
        errors.add(:base, :only_local_print_with_print_server)
      end
    end

    # Для сервера условия такие же, как для стационарного РМ (только не требуется наличие монитора).
    # Должен быть создан системный блок (+ возможно монитор). Создавать планшет, ноутбук, все виды печатающих
    # устройств с сетевым типом подключением для серверного РМ запрещено.
    def rm_server_verification(count_all_types)
      # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
      net_printer = check_net_printer

      if (count_all_types['pc'] + count_all_types['allin1']) > 1 ||
         (count_all_types['notebook'] + count_all_types['tablet']) >= 1 ||
         (count_all_types['pc'].zero? && count_all_types['allin1'].zero?) ||
         net_printer
        errors.add(:base, :wrong_rm_server_composition)
      end

      if (count_all_types['pc'] + count_all_types['allin1']) > 1
        errors.add(:base, :rm_server_only_one_pc_or_allin1)
      end
      if (count_all_types['notebook'] + count_all_types['tablet']) >= 1
        errors.add(:base, :rm_server_forbid_notebook_and_tablet)
      end
      if count_all_types['pc'].zero? && count_all_types['allin1'].zero?
        errors.add(:base, :rm_server_at_least_one_pc_or_allin1)
      end
      errors.add(:base, :rm_server_forbid_net_printer) if net_printer
    end

    # Проверка, пытается ли пользователь создать сетевой принтер.
    def check_net_printer
      # Объект свойства "Тип подключения".
      @property = InvProperty.includes(:inv_property_lists).find_by(name: 'connection_type')
      # property_list_id со значением 'network' свойства connection_type из объекта @property.
      network_prop_list_id = @property.inv_property_lists.find do |list|
        list['value'] == 'network'
      end['property_list_id']
      # Массив объектов с именами заданным в InvType::ALL_PRINT_TYPES.
      all_print_objects = @types.select do |type_obj|
        InvType::ALL_PRINT_TYPES.find { |type_name| type_obj['name'] == type_name }
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

    # Создать переменную @type (класс InvType), если она не существует.
    def inv_type
      @type ||= InvType.find_by(name: 'pc')
    end

    # Посчитать число принтеров с сетевым и локальным типом подключения. Возвращает объект printer_count.
    def set_printer_count
      printer_count = {
        # Число печатающих устройств с сетевым подключением
        net: 0,
        # Число печатающих устройств с локальным подключением
        loc: 0
      }
      # property_list_id со значением 'network' свойства connection_type из объекта @property.
      net_prop_list_id = @property.inv_property_lists.find { |list| list['value'] == 'network' }['property_list_id']
      # property_list_id со значением 'local' свойства connection_type из объекта @property.
      loc_prop_list_id = @property.inv_property_lists.find { |list| list['value'] == 'local' }['property_list_id']
      # Массив объектов с именами заданным в InvType::ALL_PRINT_TYPES.
      all_print_objects = @types.select do |type_obj|
        InvType::ALL_PRINT_TYPES.find { |type_name| type_obj['name'] == type_name }
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
          printer_count[:net] += 1
        elsif tmp_inv_type && item_prop_list_id == loc_prop_list_id
          printer_count[:loc] += 1
        end
      end

      printer_count
    end
  end
end
