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
        return false unless wrap_order_with_transaction
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
        item_id_arr = @order_params['operations_attributes'].map { |attr| attr['invent_item_id'] }.reject(&:nil?)
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

      def wrap_order_with_transaction
        Order.transaction do
          begin
            Array.wrap(@order_params).each do |param|
              init_order(param)
              return false unless fill_order_arr
            end

            @orders_arr.each do |order|
              save_order(order)

              Invent::Item.transaction(requires_new: true) do
                begin
                  order.item_to_orders.each { |io| io.inv_item.update!(status: :waiting_bring) }
                rescue ActiveRecord::RecordNotSaved
                  raise ActiveRecord::Rollback
                end
              end
            end

            @data = @orders_arr.size

            true
          rescue ActiveRecord::RecordNotSaved
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
        @order.item_to_orders.each do |io|
          begin
            item = Item.find_or_create_by!(invent_item_id: io[:invent_item_id]) do |w_item|
              w_item.inv_item = io.inv_item
              w_item.type = io.inv_item.type
              w_item.model = io.inv_item.model
              w_item.warehouse_type = :returnable
              w_item.used = true
            end
          rescue ActiveRecord::RecordNotUnique
            item = Item.find(io[:invent_item_id])
          end

          @order.operations.select { |op| op.invent_item_id == io.invent_item_id }.each do |op|
            op.item = item

            if Invent::Type::TYPE_WITH_FILES.include?(op.item.inv_item.type.name)
              op.item_model = op.item.inv_item.get_item_model
            end
          end
        end
      end

      def save_order(order)
        return if order.save

        error[:object] = order.errors
        error[:full_message] = order.errors.full_messages.join('. ')
        raise 'Ордер не сохранен'
      end
    end
  end
end
