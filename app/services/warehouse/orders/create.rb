module Warehouse
  module Orders
    # Создание приходного ордера
    class Create < BaseService
      attr_reader :error

      def initialize(current_user, order_params)
        @error = {}
        @current_user = current_user
        @order_params = order_params
      end

      def run
        init_order
        return false unless wrap_order_with_transaction
        broadcast_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_order
        @order = Order.new(@order_params)
        @order.set_creator(current_user)
      end

      def wrap_order_with_transaction
        @order.transaction do
          begin
            find_or_create_warehouse_items
            save_order

            Invent::Item.transaction do
              update_items
            end

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

          @order.operations.build(item: item, item_model: item.item_model, shift: 1)
        end
      end

      def update_items
        @order.item_to_orders.each { |io| io.inv_item.update!(status: :waiting_bring) }
      end

      def save_order
        return if @order.save

        error[:object] = @order.errors
        error[:full_message] = @order.errors.full_messages.join('. ')
        raise 'Ордер не сохранен'
      end
    end
  end
end
