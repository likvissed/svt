module Warehouse
  class Item < BaseWarehouse
    self.table_name = "#{table_name_prefix}items"

    has_many :operations, inverse_of: :item, dependent: :nullify

    belongs_to :inv_item, class_name: 'Invent::Item', foreign_key: 'invent_item_id', optional: true
    belongs_to :type, class_name: 'Invent::Type', optional: true
    belongs_to :model, class_name: 'Invent::Model', optional: true

    validates :warehouse_type, :item_type, :item_model, presence: true
    validates :used, inclusion: { in: [true, false] }
    validates :inv_item, uniqueness: true, allow_nil: true
    validates :count, :count_reserved, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validate :uniq_item_model, if: -> { !used }
    validate :max_count, if: -> { inv_item }
    validate :compare_counts, if: -> { count && count_reserved }

    after_initialize :set_initial_count, if: -> { new_record? }
    before_validation :set_string_values
    before_destroy :prevent_destroy, prepend: true

    enum warehouse_type: { without_invent_num: 1, with_invent_num: 2 }

    attr_accessor :was_created

    protected

    def set_initial_count
      self.count ||= 0
      self.count_reserved ||= 0
    end

    def set_string_values
      self.item_type ||= type.short_description if type
      self.item_model ||= inv_item.try(:get_item_model) || model.try(:item_model) if inv_item || model
    end

    def uniq_item_model
      # Без первого условия спеки сервиса Warehouse::Orders::CreateOut не проходят (не понял, почему)
      return if !item_type_changed? && !item_model_changed?
      return unless self.class.exists?(item_type: item_type, item_model: item_model, used: used)

      errors.add(:item_model, :taken)
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
      elsif count_reserved > 0
        errors.add(:base, :cannot_destroy_with_count_reserved)
        throw(:abort)
      end
    end
  end
end
