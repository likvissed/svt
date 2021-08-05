module Warehouse
  module Orders
    class CreateByInvItem < BaseService
      def initialize(current_user, inv_item, operation, comment = nil)
        @current_user = current_user
        @inv_item = inv_item
        @operation = operation
        @comment = comment

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

        @order_state.broadcast_data

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
          consumer_id_tn: @inv_item.workplace.try(:id_tn),
          operation: :in,
          comment: @comment
        )
        authorize @order, :create_in?
        @order.set_creator(current_user)
        @order_state = Orders::In::DoneState.new(@order)
      end

      def init_write_off_order
        @order = Order.new(operation: :write_off, comment: @comment)
        authorize @order, :create_write_off?
        @order.skip_validator = true
        @order.set_creator(current_user)
        @order_state = Orders::WriteOff::ProcessingState.new(@order)
      end

      def set_in_operations
        # Добавление в приходный ордер свойств техники со штрих-кодом
        if @inv_item.warehouse_items.present?
          @inv_item.warehouse_items.each do |w_item|
            new_op = @order.operations.build(
              shift: 1,
              status: :done,
              item_type: w_item.item_type,
              item_model: w_item.item_model,
              item_id: w_item.id
            )
            new_op.set_stockman(current_user)

            new_op.item.count = 1
            new_op.item.status = :used
            new_op.item.invent_property_value.mark_for_destruction
          end
        end

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

        # Добавление в ордер на списание свойств техники со штрих-кодом
        if @inv_item.warehouse_items.present?
          @inv_item.warehouse_items.each do |w_item|
            new_op = @order.operations.build(
              shift: -1,
              status: :processing,
              item_type: w_item.item_type,
              item_model: w_item.item_model,
              item_id: w_item.id
            )
            new_op.item.count = 1
            new_op.item.count_reserved = 1
            new_op.item.status = :waiting_write_off
            new_op.set_stockman(current_user)
          end
        end

        op = @order.operations.build(
          item: @inv_item.warehouse_item,
          shift: -1,
          status: :processing,
          item_type: @inv_item.type.short_description,
          item_model: @inv_item.full_item_model
        )
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
