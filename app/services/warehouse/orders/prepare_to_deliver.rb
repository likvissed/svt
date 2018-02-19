module Warehouse
  module Orders
    # Загрузить данные об ордере для редактирования
    class PrepareToDeliver < BaseService
      def initialize(current_user, order_id, order_params)
        @error = {}
        @data = {}
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params
      end

      def run
        find_order
        search_inv_items
        return false unless validate_order
        prepare_params

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.find(@order_id)
        @order.assign_attributes(@order_params)
      end

      def search_inv_items
        data[:selected_op] = @order.operations.select { |op| op.status_changed? && op.done? }
        @rejected = @order.operations.reject { |op| op.status_changed? && op.done? }.map { |op| op.item.try(:inv_item).try(:item_id) }.compact

        @finded_inv_items = []
        data[:selected_op].each do |op|
          op.set_stockman(current_user)

          if op.item.inv_item
            @finded_inv_items << op.item.inv_item.item_id
          else
            op.invent_item_id = @order.inv_items.not_by_items(@finded_inv_items).not_by_items(@rejected).where(type_id: op.item.type_id).where(model_id: op.item.model_id).first.try(:item_id)
            @finded_inv_items << op.invent_item_id if op.invent_item_id
          end
        end

        if data[:selected_op].empty?
          error[:full_message] = I18n.t('activemodel.errors.models.warehouse/orders/execute.operation_not_selected')
          raise 'Техника не выбрана'
        end
      end

      def validate_order
        return true if @order.valid?

        process_order_errors(@order)
        false
      end

      def prepare_params
        data[:inv_items_attributes] = Invent::Item.where(item_id: @finded_inv_items.compact).includes(:model, property_values: :property_list)
                                        .as_json(
                                          include: {
                                            property_values: {
                                              include: [:property, :property_list]
                                            }
                                          },
                                          methods: :get_item_model
                                        )
        data[:inv_items_attributes].each do |item|
          item['id'] = item['item_id']

          item.delete('item_id')
        end

        data[:selected_op] = data[:selected_op].as_json(methods: :invent_item_id, only: :warehouse_operation_id)
      end
    end
  end
end
