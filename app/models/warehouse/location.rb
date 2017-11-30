module Warehouse
  class Location < BaseWarehouse
    self.primary_key = :warehouse_location_id
    self.table_name = "#{table_name_prefix}locations"

    has_many :operations, foreign_key: 'warehouse_location_id', dependent: :restrict_with_error
    has_many :items, through: :operations
  end
end
