module Invent
  class ModelPropertyList < BaseInvent
    self.primary_key = :model_property_list_id
    self.table_name = "#{table_name_prefix}model_property_list"

    belongs_to :model, optional: false
    belongs_to :property, optional: false
    belongs_to :property_list, optional: false
  end
end
