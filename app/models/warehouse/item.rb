module Warehouse
  class Item < BaseWarehouse
    self.primary_key = :warehouse_item_id
    self.table_name = "#{table_name_prefix}items"

    belongs_to :inv_item, class_name: 'Invent::InvItem', foreign_key: 'invent_item_id'
    belongs_to :inv_type, class_name: 'Invent::InvType', foreign_key: 'type_id'
    belongs_to :inv_model, class_name: 'Invent::InvModel', foreign_key: 'model_id'
  end
end
