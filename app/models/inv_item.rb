class InvItem < Netadmin
  self.primary_key  = :item_id
  self.table_name   = :invent_item

  has_many :inv_property_values, foreign_key: 'item_id', dependent: :destroy
  belongs_to :inv_type, foreign_key: 'type_id'
  belongs_to :workplace, optional: true

  delegate :inv_properties, to: :inv_type

  validates :type_id, presence: true
end