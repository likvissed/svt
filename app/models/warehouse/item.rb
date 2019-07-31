module Warehouse
  class Item < BaseWarehouse
    self.table_name = "#{table_name_prefix}items"

    has_many :operations, inverse_of: :item, dependent: :nullify
    has_many :supplies, through: :operations, source: :operationable, source_type: 'Warehouse::Supply'
    has_many :orders, through: :operations, source: :operationable, source_type: 'Warehouse::Order'
    has_many :property_values, -> { left_outer_joins(:property).order('invent_property.property_order').includes(:property) },
             inverse_of: :item, dependent: :destroy, foreign_key: 'warehouse_item_id'

    belongs_to :inv_item, class_name: 'Invent::Item', foreign_key: 'invent_item_id', optional: true
    belongs_to :inv_type, class_name: 'Invent::Type', foreign_key: 'invent_type_id', optional: true
    belongs_to :inv_model, class_name: 'Invent::Model', foreign_key: 'invent_model_id', optional: true

    accepts_nested_attributes_for :property_values, allow_destroy: true

    validates :warehouse_type, :item_type, :item_model, presence: true
    validates :inv_item, uniqueness: true, allow_nil: true
    validates :count, :count_reserved, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validates :invent_num_start, :invent_num_end, numericality: { greater_than_or_equal_to: 0 }, presence: true, if: -> { warehouse_type.to_s == 'with_invent_num' && new? }
    validate :max_count, if: -> { inv_item }
    validate :compare_counts, if: -> { count && count_reserved }
    validate :compare_invent_nums_with_reserved, if: -> { warehouse_type.to_s == 'with_invent_num' && new? && (invent_num_start_changed? || invent_num_end_changed?) }

    after_initialize :set_initial_count, if: -> { new_record? }
    before_validation :set_string_values
    before_destroy :prevent_destroy, prepend: true
    before_update :prevent_update, if: -> { warehouse_type.to_s == 'with_invent_num' && !allow_update_model_or_type }, prepend: true

    scope :show_only_presence, ->(_attr = nil) { where('count > count_reserved') }
    scope :status, ->(status) { where(status: status) }
    scope :item_type, ->(item_type) { where(item_type: item_type) }
    scope :barcode, ->(barcode) { where(barcode: barcode) }
    scope :item_model, ->(item_model) { where('item_model LIKE ?', "%#{item_model}%") }
    scope :invent_num, ->(invent_num) do
      left_outer_joins(:inv_item).where('invent_item.invent_num LIKE ?', "%#{invent_num}%").limit(RECORD_LIMIT)
    end
    scope :invent_item_id, ->(invent_item_id) { where(invent_item_id: invent_item_id) }

    enum warehouse_type: { without_invent_num: 1, with_invent_num: 2 }
    enum status: { non_used: 1, used: 2, waiting_write_off: 3, written_off: 4 }

    # was_created - ставится, если техника была создана (используется внутри сервиса Warehouse::Orders::BaseService).
    # allow_update_model_or_type - разрешает обновить технику на складе, даже если модели или тип ихменились.
    attr_accessor :was_created, :allow_update_model_or_type

    def order_operations
      operations.where(operationable_type: 'Warehouse::Order')
    end

    def supply_operations
      operations.where(operationable_type: 'Warehouse::Supply')
    end

    def inv_items
      Invent::Item.left_outer_joins(:warehouse_inv_item_to_operations).where(warehouse_inv_item_to_operations: { operation: order_operations })
    end

    def generate_invent_num(index = 0)
      return unless invent_num_end

      existing_invent_nums = Invent::Item.pluck(:invent_num)
      (invent_num_start..invent_num_end).to_a.reject { |el| existing_invent_nums.include?(el.to_s) }[0 + index]
    end

    def new?
      status.to_s == 'non_used'
    end

    def used?
      status.to_s == 'used'
    end

    def written_off?
      status.to_s == 'written_off'
    end

    protected

    def set_initial_count
      self.count ||= 0
      self.count_reserved ||= 0
    end

    def set_string_values
      self.item_type ||= inv_type.short_description if inv_type
      self.item_model ||= inv_item.try(:full_item_model) || inv_model.try(:item_model) if inv_item || inv_model
    end

    def max_count
      return if count <= 1

      errors.add(:count, :max_count_exceeded)
    end

    def compare_counts
      return if count >= count_reserved

      errors.add(:base, :out_of_stock, type: item_type)
    end

    def prevent_destroy
      op = operations.find(&:processing?)
      if op
        errors.add(:base, :cannot_destroy_with_processing_operation, order_id: op.operationable.id)
        throw(:abort)
      elsif count_reserved.positive?
        errors.add(:base, :cannot_destroy_with_count_reserved)
        throw(:abort)
      end
    end

    def compare_invent_nums_with_reserved
      return unless invent_num_end

      nums = inv_items.pluck(:invent_num)
      return unless nums.any? { |num| !num.to_i.zero? && !num.to_i.between?(invent_num_start, invent_num_end) }

      errors.add(:base, :invent_num_pool_is_too_small, model: item_model)
    end

    def prevent_update
      return if orders.empty?
      return unless invent_type_id_changed? || item_type_changed? || invent_model_id_changed? || item_model_changed?

      errors.add(:base, :cannot_update_with_orders)
      throw(:abort)
    end
  end
end
