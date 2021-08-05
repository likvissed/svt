module Warehouse
  class Order < BaseWarehouse
    self.table_name = "#{table_name_prefix}orders"

    # Наименование типов техники, для которой необходимо назначать получателя техники со склада перед исполнением расходного ордера
    LIST_TYPE_FOR_ASSIGN_OP_RECEIVER = Invent::Type.where(name: %w[laminator pc monitor ups allin1 notebook tablet projector tv camera other]).pluck(:short_description).map(&:downcase).freeze

    has_many :operations, as: :operationable, dependent: :destroy, inverse_of: :operationable
    has_many :inv_item_to_operations, through: :operations
    has_many :inv_items, through: :operations
    has_many :items, through: :operations
    has_one :attachment, dependent: :destroy, foreign_key: 'order_id', class_name: 'AttachmentOrder', inverse_of: :order

    belongs_to :inv_workplace, foreign_key: 'invent_workplace_id', class_name: 'Invent::Workplace', optional: true

    validates :operation, :status, :creator_fio, presence: true
    # validates :consumer_dept, presence: true, if: -> { in? && done? }
    validates :validator_fio, presence: { message: :empty }, if: -> { out? && !skip_validator }
    validates :closed_time, presence: true, if: -> { done? }
    validates :invent_workplace_id, presence: true, if: -> { out? }
    validates :invent_num, presence: true, if: -> { operation == 'out' && operations.any? { |oop| oop.item.present? && oop.item.warehouse_type == 'without_invent_num' && oop.item.item.blank? } }

    validate :presence_consumer, if: -> { operations.any?(&:done?) && !write_off? }
    validate :at_least_one_operation
    validate :validate_in_order, if: -> { in? }
    validate :validate_write_off_order, if: -> { write_off? }
    validate :present_invent_workplace_id, if: -> { out? }
    validate :present_user_iss
    validate :present_item_for_barcode, if: -> { operation == 'out' && invent_num.present? && property_with_barcode == true }
    validate :check_absent_warehouse_items_for_inv_item, if: -> { execute_in == true }

    after_initialize :set_initial_status, if: -> { new_record? }
    before_validation :set_consumer, if: -> { consumer_fio.blank? || consumer_id_tn.blank? }
    before_validation :set_closed_time, if: -> { done? && status_changed? }
    before_validation :set_workplace_inv_items, if: -> { errors.empty? && any_inv_item_to_operation? && new_record? && in? }
    before_validation :set_workplace_w_item, if: -> { errors.empty? && any_w_item_have_inv_item? && new_record? && in? }

    before_validation :set_consumer_dept_out, if: -> { out? }
    before_validation :set_consumer_dept_in, if: -> { in? }
    before_validation :calculate_status, unless: -> { dont_calculate_status }
    before_update :prevent_update_done_order
    before_update :prevent_update_attributes
    before_destroy :prevent_destroy, prepend: true

    scope :id, ->(id) { where(id: id) }
    scope :invent_workplace_id, ->(invent_workplace_id) { where(invent_workplace_id: invent_workplace_id) }
    scope :consumer_dept, ->(dept) { where(consumer_dept: dept) }
    scope :operation, ->(op) { where(operation: op) }
    scope :creator_fio, ->(creator_fio) { where('creator_fio LIKE ?', "%#{creator_fio}%") }
    scope :consumer_fio, ->(consumer_fio) { where('consumer_fio LIKE ?', "%#{consumer_fio}%") }
    scope :invent_num_inv_items, ->(invent_num) { joins(:inv_items).where(invent_item: { invent_num: invent_num }) }
    scope :invent_num, ->(invent_num) do
      where(invent_num: invent_num)
        .or(where(id: invent_num_inv_items(invent_num).pluck(:id)))
    end

    scope :barcode_for_warehouse_item, ->(barcode) do
      joins(operations: { item: :barcode_item }).where(invent_barcodes: { id: barcode })
    end
    scope :barcode_for_invent_item, ->(barcode) do
      joins(inv_items: :barcode_item ).where(invent_barcodes: { id: barcode })
    end
    scope :barcode, ->(barcode) do
      barcode_for_warehouse_item(barcode).presence || barcode_for_invent_item(barcode)
    end

    scope :show_only_with_attachment, ->(attr = nil) { joins(:attachment) unless attr.nil? }

    enum operation: { out: 1, in: 2, write_off: 3 }
    enum status: { processing: 1, done: 2 }

    accepts_nested_attributes_for :operations, allow_destroy: true

    attr_accessor :consumer_tn
    # Флаг указывает, что расходный ордер валидный без поля validator_fio (нужно в случаях изменения позиций ордера)
    attr_accessor :skip_validator
    # Флаг указывает, что нужно пропустить вычисление статуса
    attr_accessor :dont_calculate_status
    # Флаг указывает, что нужно проверить инв.№ техники на РМ и чтобы она соответствовала назначению штрих-кода
    attr_accessor :property_with_barcode
    # # Флаг указывает, что приходный ордер исполняется
    attr_accessor :execute_in

    def set_creator(user)
      self.creator_id_tn = user.id_tn
      self.creator_fio = user.fullname
    end

    def set_validator(user)
      self.validator_id_tn = user.try(:id_tn)
      self.validator_fio = user.try(:fullname)
    end

    def operations_to_string
      operations.map { |op| "#{op.item_type}: #{op.item_model} (#{op.shift.abs} шт.)" }.join('; ')
    end

    def done?
      status == 'done'
    end

    def in?
      operation == 'in'
    end

    def out?
      operation == 'out'
    end

    def write_off?
      operation == 'write_off'
    end

    def any_inv_item_to_operation?
      operations.any? { |op| op.inv_item_to_operations.any? }
    end

    def any_w_item_have_inv_item?
      operations.any? { |op| op.try(:item) && op.item.item }
    end

    def consumer_from_history
      return nil if consumer_fio.blank?

      consumer = UsersReference.info_users("id==#{consumer_id_tn}").first
      return nil if consumer.blank?

      tel ||= consumer['phoneText'] if consumer['phoneText']

      {
        tn: consumer['personnelNo'],
        id_tn: consumer_id_tn,
        fullName: consumer_fio,
        phoneText: tel
      }
    end

    def find_employee_by_workplace
      return [] if inv_workplace.blank?

      UsersReference.info_users("id==#{inv_workplace.id_tn}")
    end

    # Метод возвращает в массиве технику, тип которой соответствует назначению штрих-кода
    # и если она существует на рабочем месте с инвентарным номером, который введен в ордере
    def find_inv_item_for_assign_barcode
      workplace = Invent::Workplace.find_by(workplace_id: invent_workplace_id)
      if workplace.present?
        name_type_for_barcode = []
        Invent::Property.where(assign_barcode: true).find_each { |prop| prop.types.each { |type| name_type_for_barcode << type.name } }

        invent_item = workplace.items.find { |item| item.invent_num == invent_num.to_s && name_type_for_barcode.include?(item.type.name) }

        return [invent_item] if invent_item.present?
      end

      return []
    end

    # Проверка, чтобы у invent_item не было связи с warehouse_item (т.е. назначенных свойств)
    # для тех позиций, которые отмечены на исполнение
    def check_absent_warehouse_items_for_inv_item
      operations.each do |op|
        next unless op.done? && op.inv_items.present? && op.inv_items.any? { |inv_item| inv_item.warehouse_items.present? }

        arr_type_with_barcode = op.inv_items.map { |inv_item| inv_item.warehouse_items.map(&:item_type).map(&:downcase) }.flatten

        # Возникает эта ошибка, когда сразу исполняют приходный ордер в котором имеются и техника и ее свойста (R: картридж)
        errors.add(:base, :warehouse_items_is_present, arr_type_with_barcode: arr_type_with_barcode.first)
      end
    end

    # Проверка, заполнения всех необходимых ФИО принявнего технику на складе
    def valid_op_warehouse_receiver_fio
      # Rails.logger.info "op: #{operations.inspect}".green
      operations.each do |op|
        # Если техника в операциях включена в список для назначения получающего со склада
        # и если уже позиция исполнена, то не учитывать в проверке
        next unless LIST_TYPE_FOR_ASSIGN_OP_RECEIVER.include?(op.item_type.to_s.downcase) && op.status == 'processing'

        # то проверить поле заполнения warehouse_receiver_fio
        return false if op.warehouse_receiver_fio.blank?
      end
      true
    end

    protected

    # Проверка: существует ли ответственный для существующего рабочего места
    def present_user_iss
      return if !inv_workplace || find_employee_by_workplace.present?

      errors.add(:base, :absence_responsible)
    end

    def presence_consumer
      return if consumer_fio.present? || consumer_id_tn.present? || errors.details[:consumer].any?

      errors.add(:consumer, :blank)
    end

    def at_least_one_operation
      return if operations.any? { |op| !op._destroy }

      if inv_workplace.present?
        errors.add(:base, :at_least_one_operation_for_workplace, workplace_id: inv_workplace.workplace_id)
      else
        errors.add(:base, :at_least_one_operation)
      end
    end

    def validate_in_order
      presence_consumer if operations.any?(&:done?)
      check_operation_list
      uniqueness_of_workplace if any_inv_item_to_operation? || any_w_item_have_inv_item?
      # compare_consumer_dept if any_inv_item_to_operation? && errors.empty?
      check_operation_shift

      # Эта валидация должна быть самой последней
      compare_nested_arrs if any_inv_item_to_operation? && errors.empty?
    end

    def validate_write_off_order
      return if operations.all? { |op| !op.item.new? && op.item.status_was != 'non_used' }

      errors.add(:base, :order_must_contains_only_used_items)
    end

    def present_invent_workplace_id
      return if Invent::Workplace.find_by(workplace_id: invent_workplace_id).present?

      errors.add(:base, :workplace_not_present, workplace_id: invent_workplace_id)
    end

    def set_initial_status
      self.status ||= :processing
    end

    def calculate_status
      self.status = operations.any?(&:processing?) ? :processing : :done
      self.closed_time = Time.zone.now if done? && status_changed?
    end

    def set_consumer
      if consumer_tn.present?
        user = UsersReference.info_users("personnelNo==#{consumer_tn}")
        if user.present?
          self.consumer_fio = user.first.try(:[], 'fullName')
          self.consumer_id_tn = user.first.try(:[], 'id')
        else
          errors.add(:consumer, :user_by_tn_not_found)
        end
      elsif consumer_id_tn.present?
        user = UsersReference.info_users("id=='#{consumer_id_tn}'")
        self.consumer_fio = user.first.try(:[], 'fullName') if user.present?
      elsif consumer_fio_changed? && !consumer_fio_changed?(from: nil, to: '')
        self.consumer_fio = consumer_fio.split.join(' ')
        user = UsersReference.info_users("fullName=='#{CGI.escape(consumer_fio)}'")
        if user.present?
          self.consumer_fio = user.first.try(:[], 'fullName')
          self.consumer_id_tn = user.first.try(:[], 'id')
        else
          errors.add(:consumer, :user_by_fio_not_found)
        end
      end
    end

    def set_closed_time
      self.closed_time = Time.zone.now
    end

    def set_workplace_inv_items
      self.invent_workplace_id = operations.find { |op| op.inv_items.any? }.inv_items.first.workplace_id
    end

    def set_workplace_w_item
      self.invent_workplace_id = operations.find { |op| op.try(:item).try(:item) }.item.item.workplace_id
    end

    def set_consumer_dept_out
      return unless inv_workplace

      self.consumer_dept = inv_workplace.division
    end

    def set_consumer_dept_in
      consumer_fio = '' if consumer_fio.blank?

      self.consumer_dept = inv_workplace.try(:division) || UsersReference.info_users("fullName=='#{CGI.escape(consumer_fio)}', personnelNo==#{consumer_tn}").first.try(:[], 'departmentForAccounting')
    end

    def check_operation_list
      # Если среди операций отсутствует техника без инв.№ и без назначенного штрих-кода
      return unless operations.any? { |op| op.inv_items.none? && Invent::Property::LIST_TYPE_FOR_BARCODES.exclude?(op.item_type.to_s.downcase) }

      if inv_workplace && operations.any? { |op| op.inv_items.none? }
        errors.add(:base, :cannot_have_operations_without_invent_num)
      elsif !inv_workplace && any_inv_item_to_operation?
        errors.add(:base, :cannot_have_operations_with_invent_num)
      end
    end

    def compare_nested_arrs
      inv_item_to_op_length = operations.map { |op| op.inv_item_to_operations.size }.inject(0) { |sum, x| sum + x }
      inv_item_with_w_item = operations.select do |op|
        Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item_type.to_s.downcase)
      end

      return if operations.size == inv_item_to_op_length + inv_item_with_w_item.count

      errors.add(:base, :nested_arrs_not_equals)
    end

    # Проверяет, чтобы техника ордера относилась только к одному рабочему месту
    def uniqueness_of_workplace
      # Для техники с инв.№
      wp_id_inv_items = operations.map { |op| op.inv_items.map(&:workplace_id) if op.status_was == 'processing' || op.processing? }.flatten.compact.uniq
      # Для техники без инв.№ и со штрих-кодом
      wp_id_w_items = operations.map do |op|
        if op.try(:item).try(:item).try(:workplace).present? && op.status_was == 'processing' || op.processing?
          op.try(:item).try(:item).try(:workplace_id)
        end
      end.flatten.compact.uniq

      # Если существует техника со штрих-кодом, то разрешить добовлять элементы техники в один ордер,
      # при условии одинаковых рабочих мест
      items_with_barcode = wp_id_inv_items.present? && wp_id_w_items.present? ? wp_id_inv_items == wp_id_w_items : true

      return if [0, 1].include?(wp_id_inv_items.length) && [0, 1].include?(wp_id_w_items.length) && items_with_barcode
      errors.add(:base, :uniq_workplace)
    end

    # Сравнивает, чтобы вся техника была с одного отдела (указанного в поле consumer_dept)
    def compare_consumer_dept
      division = operations.first.inv_items.first.try(:workplace).try(:division)
      return if !division || division == consumer_dept

      errors.add(:base, :dept_does_not_match, dept: consumer_dept) if count > 1
    end

    # Для приходящего ордера shift должен быть равен 1
    def check_operation_shift
      return if operations.none? { |op| op.shift != 1 }

      errors.add(:base, :shift_must_be_equal_1)
    end

    def prevent_update_done_order
      return true unless done? && !status_changed? || processing? && status_was == 'done'

      errors.add(:base, :cannot_update_done_order)
      throw(:abort)
    end

    def prevent_update_attributes
      errors.add(:inv_workplace, :cannot_update) if invent_workplace_id_changed?
      errors.add(:operation, :cannot_update) if operation_changed?
      errors.add(:consumer_dept, :cannot_update) if consumer_dept_changed? && !consumer_dept_was.nil?

      throw(:abort) if errors.any?
    end

    def prevent_destroy
      if done?
        errors.add(:base, :cannot_destroy_done)
        throw(:abort)
      elsif operations.any?(&:done?)
        errors.add(:base, :cannot_destroy_with_done_operations)
        throw(:abort)
      end
    end

    # Проверка перед созданием расходного ордера и его исполнением на существование РМ,
    # техники с инв.№ на этом РМ, и чтобы она соответствовала назначению штрих-кода
    def present_item_for_barcode
      workplace = Invent::Workplace.find_by_workplace_id(invent_workplace_id)

      if workplace.present?
        inv_item = find_inv_item_for_assign_barcode

        if inv_item.present?
          if inv_item.first.status.to_s != 'in_workplace'
            errors.add(:base, :status_item_on_workplace_not_in_workplace, item_barcode: inv_item.first.barcode_item.id)
          end

          return
        end
      else
        errors.add(:base, :workplace_not_present, workplace_id: invent_workplace_id)
        throw(:abort)
      end

      errors.add(:base, :item_not_find_on_workplace, workplace_id: invent_workplace_id)
    end
  end
end
