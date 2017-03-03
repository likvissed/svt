class InvPropertyValue < Netadmin
  self.primary_key  = :property_value_id
  self.table_name   = :invent_property_value

  belongs_to :inv_property, foreign_key: 'property_id'
  belongs_to :inv_item, foreign_key: 'item_id'

  validates :item_id, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :value, presence: true
end