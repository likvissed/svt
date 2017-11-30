module Warehouse
  class Item < BaseWarehouse
    self.primary_key = :warehouse_item_id
    self.table_name = "#{table_name_prefix}items"

    belongs_to :item, class_name: 'Invent::Item', foreign_key: 'invent_item_id'
    belongs_to :type, class_name: 'Invent::Type'
    belongs_to :model, class_name: 'Invent::Model'
  end
end
