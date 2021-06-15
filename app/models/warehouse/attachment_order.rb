module Warehouse
  class AttachmentOrder < BaseWarehouse
    self.primary_key = :id
    self.table_name = "#{table_name_prefix}attachment_orders"

    belongs_to :order, foreign_key: 'order_id', inverse_of: :attachment

    mount_uploader :document, DocumentUploader

    validate :presence_order

    def presence_order
      order = Order.find_by(id: order_id)

      if order.blank?
        errors.add(:base, :warehouse_order_is_not_present, order_id: order_id)
      else
        # Нельзя добавить документ, если ордер не исполненный или не расходный
        errors.add(:base, :warehouse_order_is_not_out_or_done) unless order.out? && order.done?

        # Нельзя добавить документ, если у ордера он уже присутствует
        errors.add(:base, :warehouse_order_is_present_attachment, order_id: order_id) if order.attachment.present?
      end
    end
  end
end
