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
    has_many :item_to_orders, class_name: 'Warehouse::ItemToOrder', foreign_key: 'invent_item_id', dependent: :destroy
    has_many :orders, through: :item_to_orders, class_name: 'Warehouse::Order'

    belongs_to :type, optional: false
    belongs_to :workplace, optional: true
    belongs_to :model, optional: true

    validates :invent_num, presence: true
    validate :presence_model, :check_mandatory, if: -> { errors.details[:type].empty? }

    before_save :set_default_model

    delegate :properties, to: :type

    accepts_nested_attributes_for :property_values, allow_destroy: true

    enum status: { waiting_take: 1, waiting_bring: 2 }

    def self.by_invent_num(invent_num)
      return all if invent_num.blank?
      where(invent_num: invent_num)
    end

    def model_exists?
      model || !item_model.empty?
    end

    def get_item_model
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

    private

    # Проверка наличия модели.
    def presence_model
      errors.add(:model, :blank) if !model && item_model.blank? && !Type::PRESENCE_MODEL_EXCEPT.include?(type.name)
    end

    def set_default_model
      self.model_id = nil if model_id.to_i.zero?
    end

    # Проверка, что все properties со свойством "mandatory: true" присутствуют.
    def check_mandatory
      @properties ||= type.properties

      @properties.where(mandatory: true).find_each do |prop|
        unless property_values.reject(&:_destroy).find { |prop_val| prop_val[:property_id] == prop.property_id }
          errors.add(:base, :property_not_filled, empty_prop: prop.short_description)
        end
      end
    end
  end
end
