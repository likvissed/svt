module Invent
  class Vendor < BaseInvent
    self.primary_key = :vendor_id
    self.table_name = "#{table_name_prefix}vendor"

    has_many :models, dependent: :destroy
    has_many :types, through: :models

    validates :vendor_name, presence: true
  end
end
