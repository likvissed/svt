module Warehouse
  module Orders
    class CreateByInvItem < BaseService
      def initialize(current_user, inv_item, operation)
        @current_user = current_user
        @inv_item = inv_item
        @operation = operation

        super
      end

      def run
        case @operation
        when :in
          init_in_order
          set_in_operations
          create_in_order
        when :write_off
          init_write_off_order
          set_write_off_operations
          create_write_off_order
        else
          raise 'Неизвестный тип операции'
        end

        broadcast_items
        broadcast_archive_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_in_order
        @order = Order.new(
          inv_workplace: @inv_item.workplace,
          consumer: @inv_item.workplace.user_iss,
          operation: :in
        )
        authorize @order, :create_in?
        @order.set_creator(current_user)
        @order_state = Orders::In::DoneState.new(@order)
      end

      def init_write_off_order
        @order = Order.new(operation: :write_off)
        authorize @order, :create_write_off?
        @order.set_creator(current_user)
        @order_state = Orders::WriteOff::DoneState.new(@order)
      end

      def set_in_operations
        op = @order.operations.build(
          shift: 1,
          status: :done,
          item_type: @inv_item.type.short_description,
          item_model: @inv_item.full_item_model
        )
        op.set_stockman(current_user)
        op.inv_item_ids = [@inv_item.item_id]
      end

      def set_write_off_operations
        new_status = @order_state.new_item_status

        op = @order.operations.build(
          item: @inv_item.warehouse_item,
          shift: -1,
          status: :done,
          item_type: @inv_item.type.short_description,
          item_model: @inv_item.full_item_model
        )
        op.set_stockman(current_user)
        op.change_inv_item(new_status)
        op.item.status = new_status
        @order_state.edit_warehouse_item_for(op)
      end

      def create_in_order
        Item.transaction do
          Order.transaction(requires_new: true) do
            Invent::Item.transaction(requires_new: true) do
              warehouse_item_in(@inv_item)
              save_order(@order)
              @order.operations.each { |op| op.inv_items.each(&:to_stock!) }
            end
          end
        end
      end

      def create_write_off_order
        save_order(@order)
      end
    end
  end
end
