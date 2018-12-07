module Warehouse
  module Orders
    # Изменение приходного ордера
    class UpdateIn < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params.to_h

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_in?

        @order = Order.find(@order_id)
        authorize @order, :update_in?
        @order_state = ProcessingState.new(@order)
        return false unless wrap_order_with_transactions

        broadcast_items
        broadcast_in_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def wrap_order_with_transactions
        assign_order_params

        Item.transaction do
          begin
            find_or_create_warehouse_items
            Invent::Item.transaction(requires_new: true) do
              update_inv_items
              save_order(@order)
            end

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          rescue ActiveRecord::RecordNotDestroyed
            process_order_errors(@order, true)

            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def assign_order_params
        @order.assign_attributes(@order_params)
        @order.set_creator(current_user)
      end

      def find_or_create_warehouse_items
        @order.operations.each do |op|
          next if op.id || op.marked_for_destruction?

          op.inv_items.each { |inv_item| warehouse_item_in(inv_item) }
        end
      end

      def update_inv_items
        return unless @order.inv_workplace

        @order.operations.each do |op|
          if op.new_record?
            op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_bring) }
          elsif op._destroy
            op.inv_items.each { |inv_item| inv_item.update!(status: :in_workplace) }
          end
        end
      end
    end
  end
end
