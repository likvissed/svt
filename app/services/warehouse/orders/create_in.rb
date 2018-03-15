module Warehouse
  module Orders
    # Создание приходного ордера
    class CreateIn < BaseService
      def initialize(current_user, order_params, done_flag = false)
        @error = {}
        @current_user = current_user
        @order_params = order_params
        @orders_arr = []
        @done_flag = done_flag
      end

      def run
        raise 'Неверные данные' if order_out?

        processing_nested_attributes if @order_params['operations_attributes']&.any?
        return false unless wrap_order_with_transactions

        if @done_flag
          broadcast_items
          broadcast_archive_orders
        else
          broadcast_in_orders
        end

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_nested_attributes
        # Массив id возвращаемой техники (с инв. номером)
        item_id_arr = @order_params['operations_attributes'].map { |op_attr| op_attr['inv_item_ids'] }.flatten.compact
        # Массив операций без инв. номера
        op_without_id_arr = @order_params['operations_attributes'].select { |op_attr| !op_attr['inv_item_ids'] || op_attr['inv_item_ids'].compact.empty? }
        # Массив объектов возвращаемой техники
        items = Invent::Item.select(:item_id, :workplace_id).find(item_id_arr)

        new_params = items.uniq(&:workplace_id).map do |item|
          order = @order_params.deep_dup
          # Выбор операций для текущего РМ из полученного массива операций
          order['operations_attributes'] = order['operations_attributes'].select do |op_attr|
            next if !op_attr['inv_item_ids']
            items.select { |i| i['workplace_id'] == item.workplace_id }.map(&:item_id).include?(op_attr['inv_item_ids'].first)
          end
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

            Invent::Item.transaction(requires_new: true) do
              @orders_arr.each do |order|
                save_order(order)

                if @done_flag
                  order.operations.each { |op| op.inv_items.each { |inv_item| inv_item.update!(status: nil, workplace: nil) } }
                else
                  order.operations.each { |op| op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_bring) } }
                end
              end
            end
            @data = @orders_arr.size

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

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

        if @done_flag
          @order.operations.each do |op|
            op.set_stockman(current_user)
            op.status = :done
          end
        end
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
        @order.operations.each do |op|
          if op.inv_items.any?
            op.inv_items.each { |inv_item| warehouse_item_in(inv_item) }
          elsif @done_flag
            op.build_item(
              warehouse_type: :without_invent_num,
              item_type: op.item_type,
              item_model: op.item_model,
              used: true,
              count: 1,
              count_reserved: 0
            )
          end
        end
      end
    end
  end
end
