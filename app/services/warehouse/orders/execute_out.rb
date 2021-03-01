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
                  Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item.item_type.to_s.downcase)
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

            next unless op.item.warehouse_type == 'without_invent_num' && Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item.item_type.to_s.downcase)

            create_or_find_w_item_with_barcode(op)
            op.item.destroy if op.item.count.zero? && op.item.count_reserved.zero? && op.item.status == 'non_used'
          end
        end
      end

      def create_or_find_w_item_with_barcode(operation)
        operation.shift.abs.times do |_i|
          # Если техника новая (status = non_used), то создается новая запись, присваивается штрих-код,
          # Иначе (status = used) находится существующая техника с созданным штрих-кодом
          warehouse_item = if operation.item.status == 'used'
                             w_item_in_operation = operation.item
                             w_item_in_operation.status = operation.item.status
                             w_item_in_operation.count = 0
                             w_item_in_operation.count_reserved = 0
                             w_item_in_operation
                           elsif operation.item.status == 'non_used'
                             w_item = Item.new(
                               warehouse_type: operation.item.warehouse_type,
                               item_type: operation.item.item_type,
                               item_model: operation.item.item_model,
                               barcode: operation.item.barcode,
                               status: operation.item.status,
                               count: 0,
                               count_reserved: 0
                             )
                             w_item
                           end
          warehouse_item.barcode_item = warehouse_item.build_barcode_item if warehouse_item.barcode_item.nil?

          next unless warehouse_item.save

          warehouse_item.create_invent_property_value(
            property_id: Invent::Property.find_by(short_description: warehouse_item.item_type.capitalize).property_id,
            item_id: @order.find_inv_item_for_assign_barcode.first.item_id,
            value: "#{warehouse_item.item_model} (#{warehouse_item.barcode_item.id})"
          )
        end
      end
    end
  end
end
