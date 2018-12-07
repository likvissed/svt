module Warehouse
  module Orders
    # Исполнить выбранные позиции указанного ордера
    class ExecuteWriteOff < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_write_off?

        find_order
        return false unless wrap_order

        broadcast_write_off_orders
        broadcast_archive_orders
        broadcast_items

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

            Invent::Item.transaction(requires_new: true) do
              save_order(@order)
              update_items if @item_ids.any?
            end

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
          op.calculate_item_count
          op.calculate_item_count_reserved
          op.inv_items.each { |inv_item| inv_item.status = :written_off }
          op.item.status = :written_off
          op.item_id
        end.compact

        op_selected
      end

      def update_items
        Item.transaction(requires_new: true) do
          @order.operations.each do |op|
            next unless @item_ids.include?(op.item_id)

            op.item.save!
          end
        end
      end
    end
  end
end
