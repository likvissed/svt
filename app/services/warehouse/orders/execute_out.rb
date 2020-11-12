module Warehouse
  module Orders
    # Исполнить выбранные позиции указанного ордера
    class ExecuteOut < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_out?

        find_order
        return false unless wrap_order

        broadcast_out_orders
        broadcast_archive_orders
        broadcast_items
        broadcast_workplaces_list

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.find(@order_id)
        authorize @order, :execute_out?
      end

      def wrap_order
        @order.with_lock('FOR UPDATE') do
          begin
            unless processing_params
              error[:full_message] = I18n.t('activemodel.errors.models.warehouse/orders/execute.operation_not_selected')
              raise 'Позиции не выбраны'
            end

            Invent::Item.transaction(requires_new: true) do
              # Проверка, если есть техника для создания со штрих-кодом, то
              # 1- техника должна существовать на РМ (поиск по инв.№); 2 - быть на РМ со статусом "in_workplace"
              new_w_item = @order.operations.any? do |op|
                op.item.warehouse_type == 'without_invent_num' && op.status_changed? && op.done? &&
                  list_type_for_barcodes.include?(op.item.item_type.to_s.downcase)
              end

              @order.property_with_barcode = true if new_w_item

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
          op.inv_items.each do |inv_item|
            inv_item.validate_serial_num_for_execute_out = true if Invent::Type::NAME_FOR_MANDATORY_SERIAL_NUM.include?(inv_item.type.name)
            inv_item.validate_prop_values = true
            inv_item.status = :in_workplace
          end
          op.item_id
        end.compact

        op_selected
      end

      def update_items
        Item.transaction(requires_new: true) do
          @order.operations.each do |op|
            next unless @item_ids.include?(op.item_id)

            op.item.save!

            next unless op.item.warehouse_type == 'without_invent_num' && list_type_for_barcodes.include?(op.item.item_type.to_s.downcase)

            create_w_item_with_barcode(op)
            op.item.destroy if op.item.count.zero? && op.item.count_reserved.zero?
          end
        end
      end

      def create_w_item_with_barcode(operation)
        operation.shift.abs.times do |_i|
          new_warehouse_item = Item.new(
            warehouse_type: operation.item.warehouse_type,
            item_type: operation.item.item_type,
            item_model: operation.item.item_model,
            barcode: operation.item.barcode,
            status: operation.item.status,
            count: 0,
            count_reserved: 0
          )
          new_warehouse_item.build_barcode_item

          next unless new_warehouse_item.save

          new_warehouse_item.create_invent_property_value(
            property_id: Invent::Property.find_by(short_description: new_warehouse_item.item_type.capitalize).property_id,
            item_id: @order.find_inv_item_for_assign_barcode.first.item_id,
            value: "#{new_warehouse_item.item_model} (#{new_warehouse_item.barcode_item.id})"
          )
        end
      end
    end
  end
end
