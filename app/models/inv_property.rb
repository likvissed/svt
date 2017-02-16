class InvProperty < Netadmin
  self.primary_key  = :property_id
  self.table_name   = :invent_property
  self.inheritance_column = 'inheritance_type'

  has_one :inv_property_value, foreign_key: 'property_id', dependent: :destroy
  has_many :inv_property_lists, foreign_key: 'property_id', dependent: :destroy
  belongs_to :inv_type, foreign_key: 'type_id'
end