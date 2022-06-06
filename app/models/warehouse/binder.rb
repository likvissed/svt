module Warehouse
  class Binder < BaseWarehouse
    self.primary_key = :id
    self.table_name = "#{table_name_prefix}binders"

    belongs_to :item, class_name: 'Warehouse::Item', foreign_key: 'warehouse_item_id', optional: false
    belongs_to :sign, class_name: 'Invent::Sign', foreign_key: 'sign_id', optional: false
  end
end
