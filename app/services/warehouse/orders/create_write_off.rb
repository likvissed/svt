module Warehouse
  module Orders
    # Создание расходного ордера
    class CreateWriteOff < BaseService
      def initialize(current_user, order_params)
        @current_user = current_user
        @order_params = order_params

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_write_off?

        init_order
        return false unless wrap_order

        broadcast_write_off_orders
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_order
        @order = Order.new(@order_params)
        authorize @order, :create_write_off?
        @order.skip_validator = true
        @order.set_creator(current_user)
      end

      def wrap_order
        prepare_inv_items

        Invent::Item.transaction do
          begin
            save_order(@order)

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red

            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def prepare_inv_items
        new_status = :waiting_write_off

        @order.operations.each do |op|
          next unless op.item

          op.change_inv_item(new_status)
          op.item.status = new_status
          op.calculate_item_count_reserved
        end
      end
    end
  end
end
