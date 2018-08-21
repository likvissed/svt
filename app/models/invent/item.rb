module Invent
  class Item < BaseInvent
    self.primary_key = :item_id
    self.table_name = "#{table_name_prefix}item"

    has_one :warehouse_item, foreign_key: 'invent_item_id', class_name: 'Warehouse::Item', dependent: :destroy
    has_many :property_values,
             -> { joins('LEFT OUTER JOIN invent_property ON invent_property_value.property_id = invent_property.property_id').order('invent_property.property_order').includes(:property) },
             inverse_of: :item, dependent: :destroy
    has_many :properties, -> { order('invent_property.property_order') }, through: :property_values
    has_many :standard_discrepancies, class_name: 'Standard::Discrepancy', dependent: :destroy
    has_many :standard_logs, class_name: 'Standard::Log'
    has_many :warehouse_inv_item_to_operations, class_name: 'Warehouse::InvItemToOperation', foreign_key: 'invent_item_id', dependent: :destroy
    has_many :warehouse_operations, through: :warehouse_inv_item_to_operations, class_name: 'Warehouse::Operation', source: :operation
    has_many :warehouse_orders, through: :warehouse_operations, source: :operationable, source_type: 'Warehouse::Order'

    belongs_to :type, optional: false
    belongs_to :workplace, optional: true
    belongs_to :model, optional: true

    validates :invent_num, presence: true, unless: -> { status == 'waiting_take' }
    validate :presence_model, :check_mandatory, if: -> { errors.details[:type].empty? && !disable_filters }

    after_initialize :set_default_values
    before_save :set_default_model
    before_destroy :prevent_destroy, prepend: true, unless: -> { destroy_from_order }

    scope :item_id, -> (item_id) { where(item_id: item_id) }
    scope :type_id, -> (type_id) { where(type_id: type_id) }
    scope :invent_num, -> (invent_num) { where('invent_num LIKE ?', "%#{invent_num}%").limit(RECORD_LIMIT) }
    scope :item_model, -> (item_model) { left_outer_joins(:model).where('invent_model.item_model LIKE :item_model OR invent_item.item_model LIKE :item_model', item_model: "%#{item_model}%") }
    scope :responsible, -> (responsible) { left_outer_joins(workplace: :user_iss).where('fio LIKE ?', "%#{responsible}%") }
    scope :status, -> (status) { where(status: status) }
    scope :properties, -> (prop) do
      return all if prop['property_id'].to_i.zero? || prop['property_value'].blank?

      if prop['exact']
        where('invent_item.item_id IN (SELECT item_id FROM invent_property_value AS val LEFT JOIN invent_property_list AS list USING(property_list_id) WHERE val.property_id = :prop_id AND (val.value = :val OR list.short_description = :val))', prop_id: prop['property_id'], val: prop['property_value'])
      else
        where('invent_item.item_id IN (SELECT item_id FROM invent_property_value AS val LEFT JOIN invent_property_list AS list USING(property_list_id) WHERE val.property_id = :prop_id AND (val.value LIKE :val OR list.short_description LIKE :val))', prop_id: prop['property_id'], val: "%#{prop['property_value']}%")
      end
    end
    scope :location_building_id, -> (building_id) do
      left_outer_joins(:workplace).where(invent_workplace: { location_building_id: building_id })
    end
    scope :location_room_id, -> (room_id) do
      left_outer_joins(:workplace).where(invent_workplace: { location_room_id: room_id })
    end
    scope :priority, -> (priority) { where(priority: priority) }

    attr_accessor :disable_filters
    attr_accessor :destroy_from_order

    delegate :properties, to: :type

    accepts_nested_attributes_for :property_values, allow_destroy: true

    enum status: { waiting_take: 1, waiting_bring: 2, prepared_to_swap: 3, in_stock: 4, in_workplace: 5 }
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

    def model_exists?
      model || item_model.present?
    end

    def get_item_model
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

    def short_item_model
      model.try(:item_model) || item_model
    end

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

    def build_property_values
      return unless type

      self.property_values = type.properties.map do |prop|
        prop_list = if model && %w[list list_plus].include?(prop.property_type)
                      model.property_list_for(prop)
                    else
                      nil
                    end

        PropertyValue.new(
          property: prop,
          property_list: prop_list,
          value: ''
        )
      end
    end

    protected

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

    # Проверка, что все properties со свойством "mandatory: true" присутствуют.
    def check_mandatory
      @properties ||= type.properties

      @properties.where(mandatory: true).find_each do |prop|
        next if property_values.reject(&:_destroy).find { |prop_val| prop_val[:property_id] == prop.property_id && prop_val.valid? }

        errors.add(:base, :property_not_filled, empty_prop: prop.short_description)
      end
    end

    def prevent_destroy
      op = warehouse_operations.find(&:processing?)
      return unless op

      errors.add(:base, :cannot_destroy_with_processing_operation, order_id: op.operationable.id)
      throw(:abort)
    end
  end
end
