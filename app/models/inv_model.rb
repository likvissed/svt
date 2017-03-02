class InvModel < Netadmin
  self.primary_key  = :model_id
  self.table_name   = :invent_model

  has_many    :inv_model_property_list, foreign_key: 'model_id', dependent: :destroy
  belongs_to  :inv_vendor, foreign_key: 'vendor_id'
  belongs_to  :inv_type, foreign_key: 'type_id'
end