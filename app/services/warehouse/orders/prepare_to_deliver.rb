module Warehouse
  module Orders
    # Загрузить данные об ордере для редактирования
    class PrepareToDeliver < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params

        super
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
        authorize @order, :prepare_to_deliver?
      end

      def search_inv_items
        data[:selected_op] = @order.operations.select { |op| op.status_changed? && op.done? }
        data[:selected_op].each { |op| op.set_stockman(current_user) }

        return true unless data[:selected_op].empty?

        error[:full_message] = I18n.t('activemodel.errors.models.warehouse/orders/execute.operation_not_selected')
        raise 'Техника не выбрана'
      end

      def validate_order
        return true if @order.valid?

        process_order_errors(@order)
        false
      end

      def prepare_params
        data[:operations_attributes] = @order.operations.includes(inv_items: [:model, property_values: :property_list])
                                         .as_json(
                                           include: {
                                             inv_items: {
                                               include: {
                                                 property_values: {
                                                   include: %i[property property_list]
                                                 }
                                               },
                                               methods: :short_item_model
                                             }
                                           }
                                         )
        data[:operations_attributes].each do |op|
          op['inv_items_attributes'] = op['inv_items']
          op['inv_items_attributes'].each do |inv_item|
            inv_item['id'] = inv_item['item_id']
            inv_item.delete('item_id')
          end
          op['status'] = :done if data[:selected_op].any? { |sel| sel.id == op['id'] }

          op.delete('inv_items')
        end
        data[:selected_op] = data[:selected_op].as_json(only: :id)
      end
    end
  end
end
