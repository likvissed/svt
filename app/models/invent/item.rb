module Invent
  class Item < BaseInvent
    self.primary_key = :item_id
    self.table_name = "#{table_name_prefix}item"

    # Содержит уровни критичности для замены батарей
    LEVELS_BATTERY_REPLACEMENT = {
      warning: 3,
      critical: 5
    }.freeze
    # Статусы, обозначающие перемещение техники
    MOVE_ITEM_TYPES = %w[prepared_to_swap waiting_bring waiting_take].freeze

    has_one :warehouse_item, foreign_key: 'invent_item_id', class_name: 'Warehouse::Item', dependent: :nullify
    has_one :barcode_item, as: :codeable, class_name: 'Barcode', dependent: :destroy, inverse_of: :codeable
    has_one :invalid_barcode, class_name: 'InvalidBarcode', foreign_key: 'item_id'
    has_many :property_values,
             -> { joins('LEFT OUTER JOIN invent_property ON invent_property_value.property_id = invent_property.property_id').order('invent_property.property_order').includes(:property) },
             inverse_of: :item, dependent: :destroy
    has_many :properties, -> { order('invent_property.property_order') }, through: :property_values
    has_many :standard_discrepancies, class_name: 'Standard::Discrepancy', dependent: :destroy
    has_many :standard_logs, class_name: 'Standard::Log'
    has_many :warehouse_inv_item_to_operations, class_name: 'Warehouse::InvItemToOperation', foreign_key: 'invent_item_id', dependent: :destroy
    has_many :warehouse_operations, through: :warehouse_inv_item_to_operations, class_name: 'Warehouse::Operation', source: :operation
    has_many :warehouse_orders, through: :warehouse_operations, source: :operationable, source_type: 'Warehouse::Order'
    has_many :warehouse_items,
             -> { joins('LEFT OUTER JOIN invent_property ON invent_property_value.property_id = invent_property.property_id') },
             through: :property_values, class_name: 'Warehouse::Item', foreign_key: 'warehouse_item_id'
    has_many :binders, class_name: 'Binder', foreign_key: 'invent_item_id'
    has_many :signs, through: :binders, class_name: 'Sign'

    belongs_to :type, optional: false
    belongs_to :workplace, optional: true
    belongs_to :model, optional: true

    validates :invent_num, presence: true, unless: -> { status == 'waiting_take' }
    validates :serial_num, presence: true, if: -> { validate_serial_num_for_execute_out }
    validates :barcode_item, presence: true

    validate :presence_model, :check_mandatory, if: -> { errors.details[:type].empty? && !disable_filters }
    validate :property_values_validation, if: -> { validate_prop_values }
    validate :invent_num_from_allowed_pool_of_numbers, if: -> { invent_num_changed? }
    validate :uniqueness_of_signs, if: -> { binders.present? }

    after_initialize :set_default_values
    before_save :set_default_model
    before_destroy :prevent_destroy, prepend: true, unless: -> { destroy_from_order }
    before_destroy :present_warehouse_items, prepend: true, if: -> { warehouse_items.present? }
    before_destroy :present_binders, prepend: true, if: -> { binders.present? }
    before_update :prevent_update
    # before_save :model_id_nil_if_model_item

    scope :barcode_item, ->(barcode_item) do
      joins("INNER JOIN #{Barcode.table_name} invent_barcodes ON invent_barcodes.codeable_id = invent_item.item_id")
        .where('invent_barcodes.id = ?', barcode_item)
    end
    scope :type_id, ->(type_id) { where(type_id: type_id) }
    scope :invent_num, ->(invent_num) { where('invent_num LIKE ?', "%#{invent_num}%").limit(RECORD_LIMIT) }
    scope :serial_num, ->(serial_num) { where('serial_num LIKE ?', "%#{serial_num}%").limit(RECORD_LIMIT) }
    scope :item_model, ->(item_model) { left_outer_joins(:model).where('invent_model.item_model LIKE :item_model OR invent_item.item_model LIKE :item_model', item_model: "%#{item_model}%") }
    scope :responsible, ->(responsible) do
      employees_ids = UsersReference.info_users("fullName=='*#{CGI.escape(responsible)}*'").map { |us| us['id'] }
      result = ['id_tn IN (?)']
      left_outer_joins(:workplace).where(result.join(' OR '), employees_ids)
    end
    scope :for_statuses, ->(status_arr) do
      result = []
      values = status_arr.map do |el|
        result << "#{table_name}.status = ?"
        el['id']
      end

      where(result.join(' OR '), *values)
    end
    scope :properties, ->(prop_arr) { prop_arr.inject(self) { |item, prop| item.property(prop) } }
    scope :property, ->(prop) do
      return all if prop['property_id'].to_i.zero? || (prop['property_value'].blank? && prop['property_list_id'].to_i.zero?)

      if !prop['property_list_id'].to_i.zero?
        where('
        invent_item.item_id
          IN
            (SELECT
              item_id
            FROM
              invent_property_value AS val
            WHERE
              val.property_id = :prop_id AND val.property_list_id = :prop_list_id
            )', prop_id: prop['property_id'], prop_list_id: prop['property_list_id'])
      elsif prop['property_value'] && prop['exact']
        where('
        invent_item.item_id
        IN
          (SELECT
            item_id
          FROM
            invent_property_value AS val
          WHERE
            val.property_id = :prop_id AND val.value = :val
          )', prop_id: prop['property_id'], val: prop['property_value'])
      else
        where('
        invent_item.item_id
        IN
          (SELECT
            item_id
          FROM
            invent_property_value AS val
          WHERE
            val.property_id = :prop_id AND val.value LIKE :val
          )', prop_id: prop['property_id'], val: "%#{prop['property_value']}%")
      end
    end
    scope :location_building_id, ->(building_id) do
      left_outer_joins(:workplace).where(invent_workplace: { location_building_id: building_id })
    end
    scope :location_room_id, ->(room_id) do
      left_outer_joins(:workplace).where(invent_workplace: { location_room_id: room_id })
    end
    scope :priority, ->(priority) { where(priority: priority) }
    scope :workplace_count_id, ->(workplace_count_id) { left_outer_joins(:workplace).where(invent_workplace: { workplace_count_id: workplace_count_id }) }
    scope :id_tn, ->(id_tn) { left_outer_joins(:workplace).where(invent_workplace: { id_tn: id_tn }) }
    scope :show_only_with_binders, ->(attr = nil) do
      unless attr.nil?
        joins("INNER JOIN
          invent_binders AS binder
        ON
          binder.invent_item_id = invent_item.item_id
        ")
      end
    end
    scope :name_binder, ->(name_binder) { left_outer_joins(:binders).where('invent_binders.description LIKE :binder_description', binder_description: "%#{name_binder}%") }

    attr_accessor :disable_filters
    attr_accessor :destroy_from_order
    attr_accessor :validate_prop_values
    attr_accessor :validate_serial_num_for_execute_out

    delegate :properties, to: :type

    accepts_nested_attributes_for :property_values, allow_destroy: true
    accepts_nested_attributes_for :barcode_item, allow_destroy: true, reject_if: proc { |attributes| attributes['id'].present? }
    accepts_nested_attributes_for :binders, allow_destroy: true

    enum status: { waiting_take: 1, waiting_bring: 2, prepared_to_swap: 3, in_stock: 4, in_workplace: 5, waiting_write_off: 6, written_off: 7 }
    enum priority: { default: 1, high: 2 }

    def self.by_invent_num(invent_num)
      return all if invent_num.blank?

      where(invent_num: invent_num)
    end

    def self.by_item_id(item_id)
      return all if item_id.blank?

      where(item_id: item_id)
    end

    def self.not_by_items(rejected)
      return where('item_id IS NOT NULL') if rejected.compact.empty?

      where('item_id NOT IN (?)', rejected)
    end

    def self.by_division(division)
      return all if division.blank?

      where(workplace: { invent_workplace_count: { division: division } })
    end

    def self.by_type_id(type_id)
      return all if type_id.blank?

      where(type_id: type_id)
    end

    # Изменить параметры для отправки техники на склад.
    def to_stock!
      update!(status: :in_stock, workplace: nil, priority: :default)
    end

    # Проверка, существует ли техника
    def model_exists?
      model || item_model.present?
    end

    # Получить модель техники в виде строки (для СБ вывести его конфигурацию).
    def full_item_model
      if Type::TYPE_WITH_FILES.include?(type.name)
        @@props ||= Property.where(name: Property::FILE_DEPENDING)
        attrs = property_values.select { |prop_val| @@props.map(&:property_id).include?(prop_val.property_id) }.map(&:value).reject(&:blank?).join(' / ')
        # attrs = property_values.where(property: @props).map(&:value).reject(&:blank?).join(' / ')
        attrs = 'Конфигурация отсутствует' if attrs.blank?
        item_model.blank? ? attrs : "#{item_model}: #{attrs}"
      else
        short_item_model
      end
    end

    # Получить модель техники (только то, что указано в поле item_model или таблице models).
    def short_item_model
      model.try(:item_model) || item_model
    end

    # Получить значение свойства.
    def get_value(property)
      res = []

      if property.is_a?(Integer)
        property_values.includes(:property_list).where(property_id: property).find_each do |prop_val|
          res.push(prop_val.property_list.try(:short_description) || prop_val.value)
        end
      elsif property.is_a?(Property)
        property_values.includes(:property_list).where(property: property).find_each do |prop_val|
          res.push(prop_val.property_list.try(:short_description) || prop_val.value)
        end
      else
        raise 'Неизвестный тип свойства'
      end

      if res.empty?
        nil
      elsif res.size == 1
        res.first
      else
        res
      end
    end

    # Сгенерировать массив объектов значений свойств.
    def build_property_values(w_item, skip_validations)
      return unless type

      array_property_id = w_item.property_values.map(&:property_id)

      type.properties.each do |prop|
        add_inv_property_value(prop, '', skip_validations) unless array_property_id.include?(prop.property_id)

        w_item.property_values.where(property_id: prop.property_id).find_each do |prop_val|
          add_inv_property_value(prop, prop_val.value, skip_validations)
        end
      end
    end

    def add_inv_property_value(property, value, skip_validations = false)
      prop_list = model.property_list_for(property) if model && Property::LIST_PROPS.include?(property.property_type)

      # Не создавать пустые значения для свойств со штрих-кодом
      return if Invent::Property::LIST_TYPE_FOR_BARCODES.include?(property.short_description.to_s.downcase)

      property_values.push(
        PropertyValue.new(
          property: property,
          property_list: prop_list,
          value: value,
          skip_validations: skip_validations
        )
      )
    end

    # Проверяет необходимость замены батарей для ИБП.
    def need_battery_replacement?
      return false if type.name != 'ups' || priority != 'high'

      replacement_date_ups_prop = Property.find_by(name: :replacement_date)
      prop_val = get_value(replacement_date_ups_prop)

      return true unless prop_val

      # replacement_date = Date.strptime(prop_val, '%Y-%m')
      replacement_date = Date.parse(prop_val)
      current_time = Time.zone.now

      if battery_difference_in_years(replacement_date, current_time) > LEVELS_BATTERY_REPLACEMENT[:critical]
        {
          years: LEVELS_BATTERY_REPLACEMENT[:critical],
          type: :critical
        }
      elsif battery_difference_in_years(replacement_date, current_time) > (LEVELS_BATTERY_REPLACEMENT[:warning])
        {
          years: LEVELS_BATTERY_REPLACEMENT[:warning],
          type: :warning
        }
      else
        false
      end
    end

    # Проверяет, была ли изменена модель или свойства техники.
    def was_changed?
      attribute_before_last_save(:model_id) != model_id ||
        attribute_before_last_save(:item_model) != item_model ||
        property_values.any? do |prop_val|
          prop_val.attribute_before_last_save(:property_list_id) != prop_val.property_list_id ||
            prop_val.attribute_before_last_save(:value) != prop_val.value
        end
    end

    protected

    # Возвращает сколько полных лет назад производилась замена батарей.
    def battery_difference_in_years(replacement_date, current_date)
      d = (replacement_date.year - current_date.year).abs
      d -= 1 if replacement_date.month > current_date.month
      d
    end

    # Проверка наличия модели.
    def presence_model
      errors.add(:model, :blank) if !model && item_model.blank? && !Type::PRESENCE_MODEL_EXCEPT.include?(type.name)
    end

    def set_default_values
      self.priority ||= :default
    end

    def set_default_model
      self.model_id = nil if model_id.to_i.zero?
    end

    # def model_id_nil_if_model_item
    #   self.item_model = '' unless model_id.to_i.zero?
    # end

    # Проверка, что все properties со свойством "mandatory: true" присутствуют.
    def check_mandatory
      @properties ||= type.properties

      @properties.where(mandatory: true).find_each do |prop|
        next if property_values.reject(&:_destroy).find { |prop_val| prop_val[:property_id] == prop.property_id }

        errors.add(:base, :property_not_filled, empty_prop: prop.short_description)
      end
    end

    def prevent_destroy
      order = warehouse_orders.find(&:processing?)
      unless order
        # Для сохранения информации об удаленной техники в логах
        obj_item = {}
        obj_item[:item] = inspect
        obj_item[:barcode_item] = barcode_item.inspect
        obj_item[:property_values] = property_values.inspect
        Rails.logger.info "destroy inv_item: #{obj_item.inspect}"

        return
      end

      errors.add(:base, :cannot_destroy_with_processing_operation, order_id: order.id)
      throw(:abort)
    end

    def present_warehouse_items
      arr_w_items_type = warehouse_items.map(&:item_type).uniq.join(', ')

      errors.add(:base, :cannot_destroy_warehouse_items, w_items: arr_w_items_type)
      throw(:abort)
    end

    def present_binders
      arr_signs = signs.map(&:short_description).uniq.join(', ')

      errors.add(:base, :cannot_destroy_binders, signs: arr_signs)
      throw(:abort)
    end

    # Запретить обновлять модель и тип, если имеется связанная запись в таблице warehouse_item
    def prevent_update
      return unless warehouse_item

      if item_model_changed? && !(workplace_id_changed? && workplace_id.blank?)
        cannot_update_due_warehouse_item_for(:item_model)
      elsif model_id_changed?
        cannot_update_due_warehouse_item_for(:model)
      elsif type_id_changed?
        cannot_update_due_warehouse_item_for(:type)
      end
    end

    def cannot_update_due_warehouse_item_for(name)
      errors.add(name, :cannot_update_due_warehouse_item)
      throw(:abort)
    end

    def property_values_validation
      property_values.each do |prop_val|
        next if prop_val.valid?

        errors.add(:base, prop_val.errors.full_messages.join('. '))
      end
    end

    def invent_num_from_allowed_pool_of_numbers
      w_item = warehouse_operations.last.try(:item)

      return unless w_item
      return if w_item.invent_num_start.nil? || w_item.invent_num_start.zero?
      return if invent_num.to_i.between?(w_item.invent_num_start, w_item.invent_num_end)

      errors.add(:invent_num, :not_from_allowed_pool, start_num: w_item.invent_num_start, end_num: w_item.invent_num_end)
    end

    def uniqueness_of_signs
      sign_ids = binders.map(&:sign_id)
      duplicate = sign_ids.detect { |e| sign_ids.count(e) > 1 }

      return if duplicate.blank?

      errors.add(:base, :cannot_update_with_duplicate_signs)
    end
  end
end
