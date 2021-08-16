module Warehouse
  module Orders
    # Исполнить выбранные позиции указанного ордера
    class ExecuteIn < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_in?

        find_order
        return false unless wrap_order

        if @operations_to_write_off.any?
          write_off_items
          broadcast_write_off_orders
        end

        broadcast_in_orders
        broadcast_archive_orders
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
        authorize @order, :execute_in?
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
        find_items_to_write_off

        @item_ids = @order.operations.map do |op|
          next unless op.status_changed? && op.done?
          @order.execute_in = true

          op_selected = true
          op.set_stockman(current_user)
          if op.item
            if Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item.item_type.to_s.downcase)
              op.item.count = 1
              op.item.status = :used
              op.item.invent_property_value.mark_for_destruction

              op.item
            else
              op.calculate_item_count
            end

            op.item_id
          else
            op.create_item!(
              warehouse_type: :without_invent_num,
              item_type: op.item_type,
              item_model: op.item_model,
              status: :used,
              count: op.shift,
              count_reserved: 0
            )
            nil
          end
        end.compact

        op_selected
      end

      def find_items_to_write_off
        @operations_to_write_off = @order.operations.select(&:to_write_off)
      end

      def update_items
        Invent::Item.transaction(requires_new: true) do
          @order.operations.each do |op|
            next unless @item_ids.include?(op.item_id)

            op.item.save!

            next if op.inv_items.blank?

            op.inv_items.first.to_stock!
            if Invent::Type::NAME_FOR_UNREGISTRATION_ITEM.include?(op.inv_items.first.type.name)
              UnregistrationWorker.perform_async(op.inv_items.first.invent_num, current_user.access_token)
            end
          end
        end
      end

      def write_off_items
        new_order = Order.new(operation: :write_off).as_json
        new_order['operations_attributes'] = @operations_to_write_off.map do |op|
          new_op = Order.new.operations.build
          new_op.item_id = op.item_id
          new_op.item_type = op.item_type
          new_op.item_model = op.item_model
          new_op.shift = -1

          new_op.as_json
        end

        create_write_off = CreateWriteOff.new(current_user, new_order)
        return true if create_write_off.run

        @error = create_write_off.error
        raise 'Сервис CreateWriteOff завершился с ошибкой'
      end
    end
  end
end
