class InvType < Netadmin
  self.primary_key  = :type_id
  self.table_name   = :invent_type

  has_many :inv_items, foreign_key: 'type_id', dependent: :destroy
  has_many :inv_properties, foreign_key: 'type_id', dependent: :destroy
end