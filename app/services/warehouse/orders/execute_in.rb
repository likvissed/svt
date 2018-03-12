module Warehouse
  module Orders
    # Исполнить выбранные позиции указанного ордера
    class ExecuteIn < BaseService
      def initialize(current_user, order_id, order_params)
        @error = {}
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params
      end

      def run
        raise 'Неверные данные' if order_out?

        find_order
        return false unless wrap_order
        broadcast_orders
        broadcast_items
        broadcast_workplaces

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.find(@order_id)
      end

      def wrap_order
        @order.with_lock('FOR UPDATE') do
          begin
            unless processing_params
              error[:full_message] = I18n.t('activemodel.errors.models.warehouse/orders/execute.operation_not_selected')
              raise 'Позиции не выбраны'
            end

            save_order(@order)
            update_items if @item_ids.any?

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

      def processing_params
        op_selected = false
        @order.assign_attributes(@order_params)

        @item_ids = @order.operations.map do |op|
          next unless op.status_changed? && op.done?

          op_selected = true
          op.set_stockman(current_user)
          if op.item
            op.item.count = op.item.count + op.shift.to_i
            op.item_id
          else
            op.create_item!(
              warehouse_type: :without_invent_num,
              item_type: op.item_type,
              item_model: op.item_model,
              used: true,
              count: op.shift,
              count_reserved: 0
            )
            nil
          end
        end.compact

        op_selected
      end

      def update_items
        Invent::Item.transaction(requires_new: true) do
          @order.operations.each do |op|
            next unless @item_ids.include?(op.item_id)

            op.item.save!
            op&.item&.inv_item&.update_attributes!(workplace: nil, status: nil)
          end
        end
      end
    end
  end
end
