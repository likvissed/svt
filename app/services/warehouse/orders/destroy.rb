module Warehouse
  module Orders
    # Удалить ордер
    class Destroy < BaseService
      def initialize(current_user, order_id)
        @current_user = current_user
        @order_id = order_id
      end

      def run
        Invent::Item.transaction do
          begin
            @data = Order.find(@order_id)
            authorize @data, :destroy?

            case @data.operation
            when 'in'
              in_order
              broadcast_in_orders
            when 'out'
              out_order
              broadcast_items
              broadcast_out_orders
            else
              raise 'Неизвестный тип ордера'
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

      protected

      def in_order
        @data.inv_items.each { |inv_item| inv_item.update_attributes!(status: nil) }
        destroy_order
      end

      def out_order
        InvItemToOperation.transaction(requires_new: true) do
          @data.operations.each do |op|
            op.inv_items.each { |inv_item| raise "Ошибка удаления Invent::Item #{inv_item}" unless inv_item.destroy }
          end

          Item.transaction(requires_new: true) do
            @data.operations.each do |op|
              op.item.tap { |i| i.count_reserved -= op.shift.abs }.save!(validate: false)
            end
            destroy_order
          end
        end
      end

      def destroy_order
        return if @data.destroy

        @data = data.errors.full_messages.join('. ')
        raise 'Ордер не удален'
      end
    end
  end
end
