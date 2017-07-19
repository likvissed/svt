module Invent
  class InvVendor < BaseInvent
    self.primary_key = :vendor_id
    self.table_name = :invent_vendor

    has_many :inv_models, foreign_key: 'vendor_id'
    has_many :inv_types, through: :inv_models
  end
end
