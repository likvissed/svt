module Warehouse
  class Item < BaseWarehouse
    self.primary_key = :warehouse_item_id
    self.table_name = "#{table_name_prefix}items"

    belongs_to :inv_item, class_name: 'Invent::Item', foreign_key: 'invent_item_id', optional: true
    belongs_to :type, class_name: 'Invent::Type', optional: true
    belongs_to :model, class_name: 'Invent::Model', optional: true

    validates :warehouse_type, :inv_item, :item_type, :item_model, :used, presence: true
    validates :count, :count_reserved, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validates :model, uniqueness: { scope: :type_id }, allow_nil: true
    validates :item_model, uniqueness: { scope: :item_type }

    after_initialize :set_initial_count
    before_validation :set_string_values

    enum warehouse_type: { expendable: 1, returnable: 2 }

    protected

    def set_initial_count
      self.count = 0
      self.count_reserved = 0
    end

    def set_string_values
      return unless inv_item && type

      self.item_type = type.short_description
      self.item_model = inv_item.model.try(:item_model) || inv_item.item_model
    end
  end
end
