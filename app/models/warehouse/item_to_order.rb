module Warehouse
  class ItemToOrder < BaseWarehouse
    self.primary_key = :warehouse_item_to_order_id
    self.table_name = "#{table_name_prefix}item_to_orders"

    belongs_to :inv_item, class_name: 'Invent::InvItem', foreign_key: 'invent_item_id'
    belongs_to :order
  end
end
