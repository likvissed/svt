class InvItem < Netadmin
  self.primary_key  = :item_id
  self.table_name   = :invent_item

  has_many    :inv_property_values, foreign_key: 'item_id', dependent: :destroy
  belongs_to  :inv_type, foreign_key: 'type_id'
  belongs_to  :workplace, optional: true

  delegate :inv_properties, to: :inv_type

  accepts_nested_attributes_for :inv_property_values, allow_destroy: true
                                # reject_if: proc { |attr| attr['property_id'].blank? }
end