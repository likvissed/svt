module Warehouse
  class InvItemToOperation < BaseWarehouse
    self.table_name = "#{table_name_prefix}inv_item_to_operations"

    belongs_to :inv_item, class_name: 'Invent::Item', foreign_key: 'invent_item_id'
    belongs_to :operation

    # validate :uniq_inv_item_for_processing_order

    # protected

    # def uniq_inv_item_for_processing_order
    #   # Проверка на наличие ошибки operation_already_exists (по сути это такая же валидация, только на модель Operation).
    #   # Нужно, чтобы избежать дублирования сообщения о принадлежности техники к незакрытому ордеру
    #   # Две идентичных ошибки: operation_already_exists и uniq_by_processing_order
    #   return if order && order.errors.details[:'operations.base'].any? { |err| err.value?(:operation_already_exists) }

    #   another_order = Order.includes(:inv_item_to_operations).where(status: :processing)
    #                     .find { |o| o.inv_item_to_operations.any? { |io| io.invent_item_id == invent_item_id } }
    #   return unless another_order

    #   errors.add(
    #     :inv_item,
    #     :uniq_by_processing_order,
    #     type: inv_item.type.short_description,
    #     invent_num: inv_item.invent_num,
    #     order_id: another_order.warehouse_order_id
    #   )
    # end
  end
end
