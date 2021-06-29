module Invent
  class Workplace < BaseInvent
    self.primary_key = :workplace_id
    self.table_name = "#{table_name_prefix}workplace"

    has_many :items, inverse_of: :workplace, dependent: :nullify
    has_many :orders, class_name: 'Warehouse::Order', foreign_key: 'invent_workplace_id', dependent: :nullify
    has_many :attachments, foreign_key: 'workplace_id', dependent: :destroy, inverse_of: :workplace

    belongs_to :workplace_type, optional: false
    belongs_to :workplace_specialization, optional: false
    belongs_to :workplace_count, optional: false
    belongs_to :user_iss, foreign_key: 'id_tn', optional: true
    belongs_to :iss_reference_site, foreign_key: 'location_site_id', optional: false
    belongs_to :iss_reference_building, foreign_key: 'location_building_id', optional: false
    belongs_to :iss_reference_room, foreign_key: 'location_room_id', optional: false

    validates :id_tn,
              presence: true,
              numericality: { only_integer: true },
              reduce: true, unless: :status_freezed?
    validates :id_tn, user_iss_by_id_tn: true, unless: -> { errors.any? || status_freezed? }
    validates :freezing_time, presence: true, if: -> { status == 'temporary' }
    validates :comment, presence: true, if: -> { status == 'temporary' }
    validate :check_workplace_conditions, if: -> { workplace_type && !disabled_filters }

    before_destroy :check_items_and_attachments, prepend: true, unless: -> { hard_destroy }
    before_destroy :check_processing_orders, prepend: true

    scope :fullname, ->(fullname) do
      employees_ids = UsersReference.info_users("fullName=='*#{CGI.escape(fullname)}*'").map { |us| us['id'] }
      where('id_tn IN (?)', employees_ids)
    end
    scope :workplace_count_id, ->(workplace_count_id) { where(workplace_count_id: workplace_count_id) }
    scope :workplace_id, ->(workplace_id) { where(workplace_id: workplace_id) }
    scope :workplace_type_id, ->(workplace_type_id) { where(workplace_type_id: workplace_type_id) }
    scope :status, ->(status) { where(status: status) }
    scope :invent_num, ->(invent_num) do
      items = Invent::Item.where('invent_item.invent_num LIKE ?', "%#{invent_num}%").limit(RECORD_LIMIT)
      where(items: items.pluck(:workplace_id))
    end
    scope :location_building_id, ->(building_id) { where(location_building_id: building_id) }
    scope :location_room_id, ->(room_id) { where(location_room_id: room_id) }
    scope :show_only_with_attachments, ->(attr = nil) do
      unless attr.nil?
        joins("INNER JOIN
          invent_attachments
        ON
        invent_attachments.workplace_id = invent_workplace.workplace_id
        ")
      end
    end

    # Для тестов (от имени пользователя заполняется поле "Комната")
    attr_accessor :division, :room_category_id
    # Поле указывает, нужно ли использовать валидаторы при создании/редактировании текущей модели
    attr_accessor :disabled_filters
    # Указывает, что нужно пропустить валидацию check_items_and_attachments
    attr_accessor :hard_destroy

    delegate :division, to: :workplace_count

    accepts_nested_attributes_for :items, reject_if: proc { |attr| attr['type_id'].to_i.zero? }
    accepts_nested_attributes_for :attachments, allow_destroy: true, reject_if: proc { |attr| attr['id'].blank? }

    enum status: { confirmed: 0, pending_verification: 1, disapproved: 2, freezed: 3, temporary: 4 }

    # Удалить РМ, связанные экземпляры техники, значения их свойств, а также загруженные файлы.
    def destroy_from_***REMOVED***
      Workplace.transaction do
        begin
          destroy if items.destroy_all
        rescue ActiveRecord::RecordNotDestroyed
          errors.add(:base, :cant_destroy_items)
          raise ActiveRecord::Rollback
        end
      end
    end

    def status_freezed?
      status == 'freezed'
    end

    protected

    def check_processing_orders
      return if orders.none?(&:processing?)

      errors.add(:base, :cannot_destroy_workplace_belongs_to_processing_order)
      throw(:abort)
    end

    def check_items_and_attachments
      return if items.empty? && attachments.empty?

      errors.add(:base, :cannot_destroy_workplace_with_items) if items.exists?
      errors.add(:base, :cannot_destroy_workplace_with_attachments) if attachments.exists?
      throw(:abort)
    end

    # Проверка условий, которые должны выполняться при создании/редактировании рабочих мест.
    def check_workplace_conditions
      @types = Type.all
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
      when 'rm_equipment'
        rm_equipment_verification(count_all_types)
      else
        errors.add(:base, 'Неизвестный тип рабочего места')
      end
    end

    # Заполнить объект count_all_types и посчитать total_count.
    def set_count_all_types
      count_all_types = {}
      total_count = 0

      @types.each do |type|
        count = items.select do |item|
          # Не считать технику, если:
          # 1. Она существует, но удалена из списка РМ
          # 2. Ей присвоен статус "waiting_bring" (технику должны принести)
          next if item.item_id && !item.workplace || item.status == 'waiting_bring'

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
      net_printer = net_printer?

      if (count_all_types['pc'] + count_all_types['allin1']) > 1 ||
         (count_all_types['pc'].zero? && count_all_types['allin1'].zero?) ||
         (count_all_types['notebook'] + count_all_types['tablet']) >= 1 ||
         (count_all_types['monitor'].zero? && count_all_types['allin1'].zero?) ||
         net_printer
        errors.add(:base, :wrong_rm_pk_composition)
      end

      errors.add(:base, :rm_pk_only_one_pc_or_allin1) if (count_all_types['pc'] + count_all_types['allin1']) > 1
      errors.add(:base, :rm_pk_at_least_one_pc_or_allin1) if (count_all_types['pc'] + count_all_types['allin1']).zero?
      errors.add(:base, :rm_pk_forbid_notebook_and_tablet) if (count_all_types['notebook'] + count_all_types['tablet']) >= 1
      errors.add(:base, :rm_pk_at_least_one_monitor) if count_all_types['monitor'].zero? && count_all_types['allin1'].zero?
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

      errors.add(:base, :at_least_one_notebook_or_tablet) if (count_all_types['notebook'] + count_all_types['tablet']).zero?
      errors.add(:base, :only_notebook_or_tablet) if total_count != 0 && total_count != (count_all_types['notebook'] + count_all_types['tablet'])
      errors.add(:base, :only_one_notebook_or_tablet) if total_count > 1 && (count_all_types['notebook'] + count_all_types['tablet']) == total_count
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
      @property = Property.includes(:property_lists).find_by(name: 'connection_type')
      counter = printer_count

      if (counter[:net] + count_all_types['3d_printer'] + count_all_types['print_server']).zero? ||
         counter[:net] > 1 ||
         counter[:net] == 1 && counter[:net] != total_count ||
         count_all_types['3d_printer'] > 1 ||
         count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer'] ||
         count_all_types['print_server'] > 1 ||
         count_all_types['print_server'] == 1 && (count_all_types['print_server'] + counter[:loc]) != total_count ||
         total_count != 0 && (counter[:net] + count_all_types['3d_printer'] + count_all_types['print_server']).zero?
        errors.add(:base, :wrong_rm_net_print_composition)
      end

      errors.add(:base, :at_least_one_print) if (counter[:net] + count_all_types['3d_printer'] + count_all_types['print_server']).zero?

      if counter[:net] > 1
        errors.add(:base, :only_one_net_print)
      elsif counter[:net] == 1 && counter[:net] != total_count
        errors.add(:base, :net_print_without_any_devices)
      end

      if count_all_types['3d_printer'] > 1
        errors.add(:base, :only_one_3d_printer)
      elsif count_all_types['3d_printer'] == 1 && total_count != count_all_types['3d_printer']
        errors.add(:base, :_3d_printer_without_any_devices)
      end

      if count_all_types['print_server'] > 1
        errors.add(:base, :only_one_print_server)
      elsif count_all_types['print_server'] == 1 && (count_all_types['print_server'] + counter[:loc]) != total_count
        errors.add(:base, :only_local_print_with_print_server)
      end
    end

    # Для сервера условия такие же, как для стационарного РМ (только не требуется наличие монитора).
    # Должен быть создан системный блок (+ возможно монитор). Создавать планшет, ноутбук, все виды печатающих
    # устройств с сетевым типом подключением для серверного РМ запрещено.
    def rm_server_verification(count_all_types)
      # Флаг, показывающий, пытается ли пользователь создать печатающее устройство с сетевым типом подключения.
      net_printer = net_printer?

      if (count_all_types['pc'] + count_all_types['allin1']) > 1 ||
         (count_all_types['notebook'] + count_all_types['tablet']) >= 1 ||
         (count_all_types['pc'].zero? && count_all_types['allin1'].zero?) ||
         net_printer
        errors.add(:base, :wrong_rm_server_composition)
      end

      errors.add(:base, :rm_server_only_one_pc_or_allin1) if (count_all_types['pc'] + count_all_types['allin1']) > 1
      errors.add(:base, :rm_server_forbid_notebook_and_tablet) if (count_all_types['notebook'] + count_all_types['tablet']) >= 1
      errors.add(:base, :rm_server_at_least_one_pc_or_allin1) if count_all_types['pc'].zero? && count_all_types['allin1'].zero?
      errors.add(:base, :rm_server_forbid_net_printer) if net_printer
    end

    # Для оборудования обязательно должна быть - хотя бы одина техника
    def rm_equipment_verification(count_all_types)
      return if count_all_types.any? { |_type, value| !value.zero? }

      errors.add(:base, :wrong_rm_equipment_composition)
      errors.add(:base, :rm_equipment_at_least_one_equipment)
    end

    # Проверка, пытается ли пользователь создать сетевой принтер.
    def net_printer?
      # Объект свойства "Тип подключения".
      @property = Property.includes(:property_lists).find_by(name: :connection_type)
      # property_list_id со значением 'network' свойства connection_type из объекта @property.
      network_prop_list_id = @property.property_lists.find { |list| list['value'] == 'network' }['property_list_id']
      # Массив объектов с именами заданным в Type::ALL_PRINT_TYPES.
      all_print_objects = @types.where(name: Type::ALL_PRINT_TYPES)

      items.each do |item|
        next if item._destroy || !item.model_exists?
        next unless all_print_objects.find { |type| type['type_id'] == item.type_id }

        # property_list_id свойства connection_type из полученных данных.
        item_prop_list_id = item.property_values.find do |val|
          val['property_id'] == @property.property_id
        end['property_list_id']

        # Проверка, пытается ли пользователь создать сетевое печатающее устройство.
        return true if item_prop_list_id == network_prop_list_id
      end

      false
    end

    # Посчитать число принтеров с сетевым и локальным типом подключения. Возвращает объект printer_count.
    def printer_count
      printer_count = {
        # Число печатающих устройств с сетевым подключением
        net: 0,
        # Число печатающих устройств с локальным подключением
        loc: 0
      }
      # property_list_id со значением 'network' свойства connection_type из объекта @property.
      net_prop_list_id = @property.property_lists.find { |list| list['value'] == 'network' }['property_list_id']
      # property_list_id со значением 'local' свойства connection_type из объекта @property.
      loc_prop_list_id = @property.property_lists.find { |list| list['value'] == 'local' }['property_list_id']
      # Массив объектов с именами заданным в Type::ALL_PRINT_TYPES.
      all_print_objects = @types.where(name: Type::ALL_PRINT_TYPES)

      items.each do |item|
        next if item._destroy || !item.model_exists?

        # Type, у которого type_id совпадает с одним из all_print_objects
        tmp_type = all_print_objects.find { |type| type['type_id'] == item.type_id }
        next unless tmp_type

        # property_list_id свойства connection_type из полученных данных.
        item_prop_list_id = item.property_values.find do |val|
          val['property_id'] == @property.property_id
        end['property_list_id']

        # Проверка, пытается ли пользователь создать сетевое печатающее устройство.
        if tmp_type && item_prop_list_id == net_prop_list_id
          printer_count[:net] += 1
        elsif tmp_type && item_prop_list_id == loc_prop_list_id
          printer_count[:loc] += 1
        end
      end

      printer_count
    end
  end
end
