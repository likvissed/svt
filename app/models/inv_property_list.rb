class InvPropertyList < Netadmin
  self.primary_key  = :property_list_id
  self.table_name   = :invent_property_list

  belongs_to :inv_property, foreign_key: 'property_id'
end