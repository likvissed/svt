module Invent
  class InvPropertyToType < BaseInvent
    self.primary_key = :property_to_type_id
    self.table_name = :invent_property_to_type

    belongs_to :inv_type, foreign_key: 'type_id'
    belongs_to :inv_property, foreign_key: 'property_id'
  end
end
