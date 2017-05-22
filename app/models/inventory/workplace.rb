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

    validates :id_tn,
              presence: true,
              numericality: { only_integer: true },
              reduce: true
    validates :id_tn, user_iss_by_id_tn: true, unless: -> { errors.any? }
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
    validate :check_workplace_conditions, unless: -> { workplace_type_id == -1 }

    delegate :division, to: :workplace_count

    accepts_nested_attributes_for :inv_items, allow_destroy: true, reject_if: proc { |attr| attr['type_id'].to_i.zero? }

    enum status: { confirmed: 0, pending_verification: 1, disapproved: 2 }

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
        if net_printer
          errors.add(:base, :rm_pk_forbid_net_printer)
        end

      when 'rm_mob'
        # Для мобильного РМ.
        # Должен содержать только один ноутбук/планшет (остальное запрещено). Создавать другие типы оборудования
        # для мобильного РМ запрещено.

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

        if (net_printer_count + count_all_types['3d_printer'] + count_all_types['print_server']).zero? ||
           net_printer_count > 1 ||
           net_printer_count == 1 && net_printer_count != total_count ||
           count_all_types['3d_printer'] > 1 ||
           count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer'] ||
           count_all_types['print_server'] > 1 ||
           count_all_types['print_server'] == 1 &&
           (count_all_types['print_server'] + loc_printer_count) != total_count ||
           total_count != 0 && (net_printer_count + count_all_types['3d_printer'] + count_all_types['print_server'])
           .zero?
          errors.add(:base, :wrong_rm_net_print_composition)
        end

        if (net_printer_count + count_all_types['3d_printer'] + count_all_types['print_server']).zero?
          errors.add(:base, :at_least_one_print)
        end

        if net_printer_count > 1
          errors.add(:base, :only_one_net_print)

        elsif net_printer_count == 1 && net_printer_count != total_count
          errors.add(:base, :net_print_without_any_devices)
        end

        if count_all_types['3d_printer'] > 1
          errors.add(:base, :only_one_3d_printer)
        elsif count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer']
          errors.add(:base, :_3d_printer_without_any_devices)
        end

        if count_all_types['print_server'] > 1
          errors.add(:base, :only_one_print_server)
        elsif count_all_types['print_server'] == 1 &&
              (count_all_types['print_server'] + loc_printer_count) != total_count
          errors.add(:base, :only_local_print_with_print_server)
        end

      when 'rm_server'
        # Для сервера условия такие же, как для стационарного РМ (только не требуется наличие монитора).
        # Должен быть создан системный блок (+ возможно монитор). Создавать планшет, ноутбук, все виды печатающих
        # устройств с сетевым типом подключением для серверного РМ запрещено.

        # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
        # net_printer = false
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
        if net_printer
          errors.add(:base, :rm_server_forbid_net_printer)
        end
      else
        errors.add(:base, 'Неизвестнй тип рабочего места')
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

    # Создать переменную @type (класс InvType), если она не существует.
    def inv_type
      @type = InvType.find_by(name: 'pc') unless @type
    end
  end
end
