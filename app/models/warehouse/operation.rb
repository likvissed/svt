module Warehouse
  class Operation < BaseWarehouse
    self.primary_key = :warehouse_operation_id
    self.table_name = "#{table_name_prefix}operations"

    belongs_to :item, foreign_key: 'warehouse_item_id'
    belongs_to :location, foreign_key: 'warehouse_location_id'
    belongs_to :stockman, class_name: 'UserIss', foreign_key: 'stockman_id_tn'
    belongs_to :operationable, polymorphic: true
  end
end
