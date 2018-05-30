module Invent
  class PropertyToType < BaseInvent
    self.primary_key = :property_to_type_id
    self.table_name = "#{table_name_prefix}property_to_type"

    belongs_to :type
    belongs_to :property
  end
end
