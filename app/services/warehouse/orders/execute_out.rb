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

        # Для проверка статуса заявки
        @order.present_request_execute_out = true if @order.request.present? && @order.request.category == 'office_equipment'

        return false unless wrap_order

        broadcast_out_orders
        broadcast_archive_orders
        broadcast_items
        broadcast_workplaces_list
        broadcast_requests

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

              assing_new_operations if @order.operations.any? { |op| Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item.item_type.to_s.downcase) }

              save_order(@order)

              if @item_ids.any?
                update_items

                # Отправка модели всех исполненных позиций за 1 раз
                if @order.present_request_execute_out == true
                  Orbita.add_event(@order.request.request_id, @current_user.id_tn, 'workflow', { message: "Выдана техника: #{@str_model_ops.join(', ')}" })
                end
              end

              # Закрываем заявку если все позиции ордера исполнены
              if @order.present_request_execute_out == true && @order.operations.all? { |op| op.done? }
                @order.request.update(status: :completed)

                Orbita.add_event(@order.request.request_id, @current_user.id_tn, 'workflow', { message: "Ордер на выдачу ВТ исполнен №#{@order.id}" })
                Orbita.add_event(@order.request.request_id, @current_user.id_tn, 'close')
              end
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
        @str_model_ops = []

        @order.assign_attributes(@order_params)
        @item_ids = @order.operations.map do |op|
          next unless op.status_changed? && op.done?

          @str_model_ops << op.item_model

          op.worker_w_receiver_fio = true if @current_user.role.name == 'worker'

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

      # Создать новую операцию для текущей техники
      #
      # В результате, например, изначально 1 операция на выдачу -2 техники
      # как результат: 2 операции и каждая с выдачей -1 техники
      def assing_new_operations
        @order_params['operations_attributes'].each do |operation|
          w_item = Item.find_by(id: operation['item_id'])

          next unless @item_ids.include?(operation['item_id']) && w_item && Invent::Property::LIST_TYPE_FOR_BARCODES.include?(w_item.item_type.to_s.downcase)

          operation['shift'].abs.times do |inc|
            new_operation = if inc.zero?
                              present_op = @order.operations.find { |op| op.id == operation['id'] }
                              present_op.shift = -1
                              present_op.status = 'done'
                              present_op
                            else
                              @order.operations.build(
                                item_id: w_item.id,
                                item_type: w_item.item_type,
                                item_model: w_item.item_model,
                                shift: -1,
                                status: 'done',
                                date: Time.zone.now
                              )
                            end

            new_operation.set_stockman(current_user)
          end
        end
      end

      def update_items
        Item.transaction(requires_new: true) do
          # Массив с id той техники, которую необходимо удалить
          @array_id_for_old_w_item = []

          @order.operations.each do |op|
            next unless @item_ids.include?(op.item_id)

            op.item.save!

            next unless op.item.warehouse_type == 'without_invent_num' && Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item.item_type.to_s.downcase)

            create_or_find_w_item_with_barcode(op)
          end

          @array_id_for_old_w_item.each { |id| Item.find_by(id: id).destroy } if @array_id_for_old_w_item.present?
        end
      end

      def create_or_find_w_item_with_barcode(operation)
        # Если техника новая (status = non_used), то создается новая запись, присваивается штрих-код,
        # Иначе (status = used) находится существующая техника с созданным штрих-кодом
        warehouse_item = if operation.item.status == 'used'
                           w_item_in_operation = operation.item
                           w_item_in_operation.status = 'used'
                           w_item_in_operation.count = 0
                           w_item_in_operation.count_reserved = 0
                           w_item_in_operation
                         elsif operation.item.status == 'non_used'
                           w_item = Item.new(
                             warehouse_type: operation.item.warehouse_type,
                             item_type: operation.item.item_type,
                             item_model: operation.item.item_model,
                             barcode: operation.item.barcode,
                             status: 'used',
                             count: 0,
                             count_reserved: 0
                           )
                           w_item
                         end
        warehouse_item.barcode_item = warehouse_item.build_barcode_item if warehouse_item.barcode_item.nil?
        warehouse_item.save

        @array_id_for_old_w_item << operation.item.id if operation.item.count.zero? &&
                                                         operation.item.count_reserved.zero? && operation.item.status == 'non_used'

        warehouse_item.create_invent_property_value(
          property_id: Invent::Property.find_by(short_description: warehouse_item.item_type.capitalize).property_id,
          item_id: @order.find_inv_item_for_assign_barcode.first.item_id,
          value: "#{warehouse_item.item_model} (#{warehouse_item.barcode_item.id})"
        )

        # Если у техники существует поставка, то назначить ее для созданной техники
        create_and_update_operation_supply(warehouse_item, operation) if warehouse_item.supplies.blank? && operation.item.supplies.present?

        # Назначить текущую технику для созданной ранее операции
        operation.update_item_without_invent_num = true
        operation.update(item: warehouse_item)
      end

      def create_and_update_operation_supply(w_item, operation)
        supply_id = operation.item.supplies.first.id

        new_operation = w_item.operations.build(
          item_id: w_item['id'],
          shift: 1,
          status: :done,
          operationable_id: supply_id,
          operationable_type: 'Warehouse::Supply',
          item_type: w_item['item_type'],
          item_model: w_item['item_model'],
          date: Time.zone.now
        )
        new_operation.set_stockman(current_user)
        new_operation.save

        # Уменьшить количество в операции существующей поставки
        present_op = operation.item.operations.find_by(operationable_type: 'Warehouse::Supply')
        present_op.shift == 1 ? present_op.destroy : present_op.update(shift: present_op.shift - 1)
      end
    end
  end
end
