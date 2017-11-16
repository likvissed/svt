module Warehouse
  class Supply < BaseWarehouse
    self.primary_key = :warehouse_supply_id
    self.table_name = "#{table_name_prefix}supplies"

    has_many :operations, as: :operationable
  end
end
