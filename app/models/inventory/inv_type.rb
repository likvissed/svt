module Inventory
  class InvType < Invent
    self.primary_key = :type_id
    self.table_name = :invent_type

    has_many :inv_items, foreign_key: 'type_id', dependent: :destroy

    has_many :inv_property_to_types, foreign_key: 'type_id', dependent: :destroy
    has_many :inv_properties, through: :inv_property_to_types

    has_many :inv_models, foreign_key: 'type_id'
    has_many :inv_vendors, through: :inv_models
  end
end
