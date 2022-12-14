module Warehouse
  module Orders
    # Удалить ордер
    class Destroy < BaseService
      def initialize(current_user, order_id)
        @current_user = current_user
        @order_id = order_id

        super
      end

      def run
        Invent::Item.transaction do
          begin
            @order = Order.find(@order_id)
            authorize @order, :destroy?
            broadcast_data

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
        @order.inv_items.each { |inv_item| inv_item.update!(status: :in_workplace) }
        destroy_order

        @order.inv_items.each do |inv_item|
          next unless inv_item.warehouse_item
          inv_item.warehouse_item.location.destroy if inv_item&.warehouse_item&.location
          inv_item.warehouse_item.update(location_id: 0)
        end
      end

      def out_order
        InvItemToOperation.transaction(requires_new: true) do
          @order.operations.each do |op|
            op.inv_items.each do |inv_item|
              if !inv_item.warehouse_item
                destroy_item(inv_item)
              else
                inv_item.update(status: :in_stock, workplace: nil)
              end
            end
          end

          Item.transaction(requires_new: true) do
            @order.operations.each do |op|
              op.mark_for_destruction
              op.calculate_item_count_reserved
              op.item.save!
            end
            destroy_order

            # Вернуть статус "Требуется создать ордер", если существует заявка
            if @order.request_id.present?
              Orbita.add_event(@order.request_id, @current_user.id_tn, 'workflow', { message: "Ордер на выдачу ВТ удален №#{@order_id}" })
              Requests::ExpectedInStock.new(@current_user, @order.request_id, false).run
            end
          end
        end
      end

      def write_off_order
        Item.transaction do
          @order.inv_items.each { |inv_item| inv_item.update!(status: :in_stock) }
          @order.operations.each do |op|
            op.mark_for_destruction
            op.calculate_item_count_reserved
            op.item.status = :used
            op.item.save!
          end
          destroy_order
        end
      end

      def destroy_item(inv_item)
        inv_item.destroy_from_order = true

        return if inv_item.destroy

        Rails.logger.info "Ошибка удаления Invent::Item: #{inv_item.errors.full_messages.join('. ')}"
        raise "Ошибка удаления Invent::Item #{inv_item.item_id}"
      end

      def destroy_order
        return if @order.destroy

        error[:full_message] = @order.errors.full_messages.join('. ')
        raise 'Ордер не удален'
      end

      def broadcast_data
        case @order.operation
        when 'in'
          in_order
          broadcast_items
          broadcast_in_orders
          broadcast_workplaces
          broadcast_workplaces_list
        when 'out'
          out_order
          broadcast_items(@order.id)
          broadcast_out_orders
          broadcast_workplaces
          broadcast_workplaces_list
          broadcast_requests
        when 'write_off'
          write_off_order
          broadcast_write_off_orders
          broadcast_items(@order.id)
        else
          raise 'Неизвестный тип ордера'
        end
      end
    end
  end
end
