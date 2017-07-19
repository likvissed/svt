module Invent
  class InvPropertyList < BaseInvent
    self.primary_key = :property_list_id
    self.table_name = "#{table_name_prefix}property_list"

    has_many :inv_model_property_lists, foreign_key: 'property_list_id'
    has_many :inv_property_values, foreign_key: 'property_list_id'
    belongs_to :inv_property, foreign_key: 'property_id'
  end
end
