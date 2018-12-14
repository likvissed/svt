module Warehouse
  module Orders
    # Изменение ордера на списание
    class UpdateWriteOff < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params.to_h
        @items_for_update = []

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_write_off?

        find_order

        return false unless wrap_order_with_transactions

        broadcast_write_off_orders
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.includes(:inv_item_to_operations, :inv_items).find(@order_id)
        assign_order_params
        authorize @order, :update_out?
      end

      def assign_order_params
        @order.assign_attributes(@order_params)
        @order.set_creator(current_user)
        @order.skip_validator = true
      end

      def wrap_order_with_transactions
        prepare_inv_items

        Item.transaction do
          begin
            Invent::Item.transaction(requires_new: true) do
              @items_for_update.each do |item|
                item.update!(status: :used)
                item&.inv_item&.update!(status: :in_stock)
              end
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

      def prepare_inv_items
        @order.operations.each do |op|
          next unless op.item

          if op.new_record?
            new_status = :waiting_write_off
            op.change_inv_item(new_status)
            op.item.status = new_status
          elsif op.marked_for_destruction?
            @items_for_update << op.item
          end

          op.calculate_item_count_reserved
        end
      end
    end
  end
end
