module Invent
  class Model < BaseInvent
    self.primary_key = :model_id
    self.table_name = "#{table_name_prefix}model"

    default_scope { order(:item_model) }

    has_many :model_property_lists, dependent: :destroy
    has_many :items, dependent: :restrict_with_error
    has_many :warehouse_items, class_name: 'Warehouse::Item', foreign_key: 'invent_model_id', dependent: :restrict_with_error

    belongs_to :vendor, optional: false
    belongs_to :type, optional: false

    validates :type, :vendor, :item_model, presence: true, reduce: true

    scope :vendor_id, ->(vendor_id) { where(vendor_id: vendor_id) }
    scope :type_id, ->(type_id) { where(type_id: type_id) }
    scope :item_model, ->(item_model) { where('item_model LIKE ?', "%#{item_model}%") }

    accepts_nested_attributes_for :model_property_lists, reject_if: proc { |attr| attr['property_id'].to_i.zero? || attr['property_list_id'].to_i.zero? }

    def property_list_for(prop)
      model_property_lists.find_by(property: prop).try(:property_list)
    end

    def fill_item_model
      return unless vendor

      if new_record?
        self.item_model = "#{vendor.vendor_name} #{item_model}"
      elsif vendor_id_changed?
        old_vendor = Vendor.find(vendor_id_was)
        self.item_model.gsub!(/^#{old_vendor.vendor_name}/, vendor.vendor_name)
      end
    end
  end
end
