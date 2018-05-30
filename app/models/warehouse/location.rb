module Warehouse
  class Location < BaseWarehouse
    self.table_name = "#{table_name_prefix}locations"

    has_many :operations, dependent: :restrict_with_error
    has_many :items, through: :operations
  end
end
