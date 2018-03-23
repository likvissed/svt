module Warehouse
  class Supply < BaseWarehouse
    self.table_name = "#{table_name_prefix}supplies"

    has_many :operations, as: :operationable, dependent: :destroy
    has_many :items, through: :operations

    accepts_nested_attributes_for :operations, allow_destroy: true

    validates :name, :date, presence: true
    validate :positive_operations_shift

    protected

    def positive_operations_shift
      return if operations.none? { |op| op.shift.negative? }

      self.errors.add(:base, :operations_can_not_have_negative_value)
    end
  end
end
