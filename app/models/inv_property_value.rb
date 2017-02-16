class InvPropertyValue < Netadmin
  self.primary_key  = :property_value_id
  self.table_name   = :invent_property_value

  belongs_to :inv_property, foreign_key: 'property_id'
  belongs_to :inv_item, foreign_key: 'item_id'
end