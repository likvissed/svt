module Warehouse
  module Orders
    class CreateByInvItem < BaseService
      def initialize(current_user, item)
        @current_user = current_user
        @item = item

        super
      end

      def run
        init_order
        set_operations
        create_order

        broadcast_items
        broadcast_archive_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_order
        @order = Order.new(
          inv_workplace: @item.workplace,
          consumer: @item.workplace.user_iss,
          operation: :in,
          skip_validator: true
        )
        authorize @order, :create_by_inv_item?
        @order.set_creator(current_user)
        @order_state = DoneState.new(@order)
      end

      def set_operations
        op = @order.operations.build(
          shift: 1,
          status: :done,
          item_type: @item.type.short_description,
          item_model: @item.full_item_model
        )
        op.set_stockman(current_user)
        op.inv_item_ids = [@item.item_id]
      end

      def create_order
        Item.transaction do
          Order.transaction(requires_new: true) do
            Invent::Item.transaction(requires_new: true) do
              warehouse_item_in(@item)
              save_order(@order)
              @order.operations.each { |op| op.inv_items.each(&:to_stock!) }
            end
          end
        end
      end
    end
  end
end
