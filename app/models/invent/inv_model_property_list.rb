module Invent
  class InvModelPropertyList < BaseInvent
    self.primary_key = :model_property_list_id
    self.table_name = :invent_model_property_list

    belongs_to :inv_model, foreign_key: 'model_id'
    belongs_to :inv_property, foreign_key: 'property_id'
    belongs_to :inv_property_list, foreign_key: 'property_list_id'
  end
end
