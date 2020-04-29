module Warehouse
  class Supply < BaseWarehouse
    self.table_name = "#{table_name_prefix}supplies"

    has_many :operations, as: :operationable, dependent: :destroy
    has_many :items, through: :operations

    accepts_nested_attributes_for :operations, allow_destroy: true

    validates :name, :date, presence: true
    validate :positive_operations_shift
    validate :checked_location_for_items, if: -> { location_attr }

    attr_accessor :location_attr
    attr_accessor :value_location_item_type

    protected

    def positive_operations_shift
      return if operations.none? { |op| op.shift.negative? }

      errors.add(:base, :operations_can_not_have_negative_value)
    end

    def checked_location_for_items
      errors.add(:base, :must_add_a_location_for_the_item, item_type: value_location_item_type)
    end
  end
end
