module Invent
  class Model < BaseInvent
    self.primary_key = :model_id
    self.table_name = "#{table_name_prefix}model"

    has_many :model_property_lists, dependent: :destroy
    has_many :items, dependent: :restrict_with_error

    belongs_to :vendor, optional: false
    belongs_to :type, optional: false
  end
end
