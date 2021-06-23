module Warehouse
  module Orders
    # Назначить ФИО принявшего технику со склада
    class AssignOperationReceiver < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_out?

        find_order
        prepare_operations

        broadcast_out_orders
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.includes(:operations).find(@order_id)

        authorize @order, :assign_operation_receiver?
      end

      def prepare_operations
        @order.assign_attributes(@order_params)

        role_worker = @current_user.role.name == 'worker'

        @order.operations.each do |op|
          # Изменяем статус на "processing", тк обновляем только поле warehouse_receiver_fio
          op.status = 'processing' if op.status_changed?
          # Изменяем статус на "done", если все галочки были сняты пользователем
          op.status = 'done' if op.status_was == 'done'

          op.worker_w_receiver_fio = true if role_worker
        end

        save_order(@order)
      end
    end
  end
end
