module Warehouse
  module Orders
    # Создание приходного ордера
    class Create < BaseService
      def initialize(current_user, order_params)
        @error = {}
        @current_user = current_user
        @order_params = order_params
        @orders_arr = []
      end

      def run
        processing_nested_attributes if @order_params['operations_attributes']&.any?
        return false unless wrap_order_with_transactions
        broadcast_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_nested_attributes
        # Массив id возвращаемой техники (с инв. номером)
        item_id_arr = @order_params['operations_attributes'].map { |attr| attr['invent_item_id'] }.compact
        # Массив операций без инв. номера
        op_without_id_arr = @order_params['operations_attributes'].select { |attr| attr['invent_item_id'].nil? }
        # Массив объектов возвращаемой техники
        items = Invent::Item.select(:item_id, :workplace_id).find(item_id_arr)

        new_params = items.uniq(&:workplace_id).map do |item|
          order = @order_params.deep_dup
          # Выбор операций для текущего РМ из полученного массива операций
          order['operations_attributes'] = order['operations_attributes'].select { |attr| items.select { |i| i['workplace_id'] == item.workplace_id }.map(&:item_id).include?(attr['invent_item_id']) }
          order['item_to_orders_attributes'] = order['operations_attributes'].map { |attr| { invent_item_id: attr['invent_item_id'] } }
          order
        end

        if op_without_id_arr.any?
          order_with_empty_op = @order_params.deep_dup
          order_with_empty_op['operations_attributes'] = op_without_id_arr
          new_params << order_with_empty_op
        end

        @order_params = new_params
      end

      def wrap_order_with_transactions
        Item.transaction do
          begin
            Array.wrap(@order_params).each do |param|
              init_order(param)
              return false unless fill_order_arr
            end

            @orders_arr.each do |order|
              save_order(order)

              Invent::Item.transaction(requires_new: true) do
                order.item_to_orders.each { |io| io.inv_item.update!(status: :waiting_bring) }
              end
            end

            @data = @orders_arr.size

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
        end

      def init_order(param)
        @order = Order.new(param)
        @order.set_creator(current_user)
      end

      def fill_order_arr
        @order.transaction(requires_new: true) do
          begin
            find_or_create_warehouse_items
            @orders_arr << @order

            true
          rescue ActiveRecord::RecordNotSaved
            raise ActiveRecord::Rollback
          end
        end
      end

      def find_or_create_warehouse_items
        @order.item_to_orders.each { |io| warehouse_item(io) }
      end
    end
  end
end
