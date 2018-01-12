module Warehouse
  class ItemToOrder < BaseWarehouse
    self.primary_key = :warehouse_item_to_order_id
    self.table_name = "#{table_name_prefix}item_to_orders"

    belongs_to :inv_item, class_name: 'Invent::Item', foreign_key: 'invent_item_id'
    belongs_to :order

    validate :uniq_inv_item_for_processing_order

    protected

    def uniq_inv_item_for_processing_order
      order = Order.includes(:item_to_orders).where(status: :processing)
                .find { |o| o.item_to_orders.any? { |io| io.invent_item_id == invent_item_id } }
      return unless order

      errors.add(
        :inv_item,
        :uniq_by_processing_order,
        type: inv_item.type.short_description,
        invent_num: inv_item.invent_num,
        order_id: order.warehouse_order_id
      )
    end
  end
end
