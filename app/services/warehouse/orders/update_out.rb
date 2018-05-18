module Warehouse
  module Orders
    # Изменение расходного ордера
    class UpdateOut < BaseService
      def initialize(current_user, order_id, order_params)
        @error = {}
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params.to_h
        @inv_items_for_destroy = []
        @inv_items_for_update = []
      end

      def run
        raise 'Неверные данные' if order_in?

        @order = Order.includes(:inv_item_to_operations, :inv_items).find(@order_id)
        authorize @order, :update?
        return false unless wrap_order_with_transactions
        broadcast_out_orders
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def wrap_order_with_transactions
        assign_order_params
        prepare_inv_items

        Invent::Item.transaction do
          begin
            Item.transaction(requires_new: true) do
              @inv_items_for_destroy.each(&:destroy!)
              @inv_items_for_update.each { |inv_item| inv_item.update(workplace: nil, status: nil) }

              update_items
              save_order(@order)
            end

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          rescue ActiveRecord::RecordNotDestroyed
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

      def prepare_inv_items
        @order.operations.each do |op|
          next unless op.item

          if op.new_record?
            op.build_inv_items(op.shift.abs, workplace: @order.inv_workplace)
          elsif op.marked_for_destruction?
            op.item.inv_item ? inv_items_for_update(op.inv_items) : inv_items_for_destroy(op.inv_items)
          elsif op.shift_changed?
            process_changed_operation(op)
          end

          op.calculate_item_count_reserved
        end
      end

      # Заполнение массива inv_items, элементы которого будут удалены из БД
      def inv_items_for_destroy(inv_items)
        @inv_items_for_destroy.concat(inv_items)
      end

      # Заполнение массива inv_items, параметры которого будут обновлены
      def inv_items_for_update(inv_items)
        @inv_items_for_update.concat(inv_items)
      end

      def update_items
        @order.operations.each { |op| op.item.save! if op.marked_for_destruction? }
      end

      def process_changed_operation(op)
        delta = op.shift_was - op.shift

        if delta.positive?
          op.build_inv_items(delta, workplace: @order.inv_workplace)
        elsif delta.negative?
          inv_items_for_destroy(op.inv_items.last(delta.abs))
        end
      end
    end
  end
end
