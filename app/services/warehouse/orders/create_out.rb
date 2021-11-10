module Warehouse
  module Orders
    # Создание расходного ордера
    class CreateOut < BaseService
      def initialize(current_user, order_params)
        @current_user = current_user
        @order_params = order_params

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_out?

        init_order
        return false unless wrap_order

        broadcast_out_orders
        broadcast_items
        broadcast_workplaces
        broadcast_workplaces_list

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_order
        @order = Order.new(@order_params)
        authorize @order, :create_out?
        @order.skip_validator = true
        @order.set_creator(current_user)
      end

      def wrap_order
        prepare_inv_items

        Invent::Item.transaction do
          begin
            save_order(@order)

            # Обновляем статус у заявки
            if @order.request.present? && @order.request.category == 'office_equipment'
              # т.к. если создает ордер администратор, то ордер автоматически утверждается и этап подтверждения пропускается
              status = @current_user.role.name == 'admin' ? 'waiting_confirmation_for_user' : 'check'

              @order.request.update(status: status)

              message = status == 'check' ? "Создан ордер №#{@order.id}" : "Создан и подтверждён ордер №#{@order.id}"
              Orbita.add_event(@order.request.number_***REMOVED***, @current_user.id_tn, 'workflow', { message: message })

              # Отправляется запрос на подтверждение пользователю
              Requests::SendAnswerToUser.new(@current_user, @order.request.request_id).run if status == 'waiting_confirmation_for_user'
            end

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
        @order.operations.each do |op|
          next unless op.item

          if op.item.warehouse_type == 'without_invent_num' && Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op.item.item_type.to_s.downcase)
            @order.property_with_barcode = true
          else
            op.build_inv_items(op.shift.abs, workplace: @order.inv_workplace, status: :waiting_take)
          end
          op.calculate_item_count_reserved
        end
      end
    end
  end
end
