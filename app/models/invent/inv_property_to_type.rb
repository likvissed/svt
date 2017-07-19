module Invent
  class InvPropertyToType < BaseInvent
    self.primary_key = :property_to_type_id
    self.table_name = "#{table_name_prefix}property_to_type"

    belongs_to :inv_type, foreign_key: 'type_id'
    belongs_to :inv_property, foreign_key: 'property_id'
  end
end
