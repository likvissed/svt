module Invent
  class PropertyList < BaseInvent
    self.primary_key = :property_list_id
    self.table_name = "#{table_name_prefix}property_list"

    has_many :model_property_lists, dependent: :restrict_with_error
    has_many :property_values, dependent: :restrict_with_error

    belongs_to :property, optional: false
  end
end
