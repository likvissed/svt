module Warehouse
  module Orders
    # Создание расходного ордера
    class CreateOut < BaseService
      def initialize(current_user, order_params)
        @error = {}
        @current_user = current_user
        @order_params = order_params
      end

      def run
        processing_params if @order_params['operations_attributes']&.any?
        init_order
        return false unless wrap_order
        broadcast_orders
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_params
        # Все задействованные элементы склада
        items = Item.includes(:inv_item).where(warehouse_item_id: @order_params['operations_attributes'].map { |op| op['warehouse_item_id'] }.compact)
        # Массив объектов выдаваемой новой техники (без инв. номеров)
        items_new = items.where(invent_item_id: nil, warehouse_type: :with_invent_num)
        # Массив объектов выдаваемой б/у техники (с инв. номерами)
        items_old = items.where('invent_item_id IS NOT NULL').where(warehouse_type: :with_invent_num).pluck(:invent_item_id)

        @order_params['inv_item_ids'] = items_old
        @order_params['inv_items_attributes'] = items_new.map do |item|
          {
            type_id: item.type ? item.type.type_id : nil,
            workplace_id: @order_params['workpalce_id'],
            model_id: item.model ? item.model.model_id : nil,
            item_model: item.item_model,
            invent_num: nil,
            serial_num: nil,
            status: :waiting_take
          }
        end.compact
      end

      def init_order
        @order = Order.new(@order_params)
        @order.set_creator(current_user)
      end

      def wrap_order
        Invent::Item.transaction do
          begin
            @order.inv_items.each { |item| item.update!(status: :waiting_take, workplace: @order.workplace, disable_filters: true) }

            Item.transaction(requires_new: true) do
              save_order(@order)
              update_items
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

      def update_items
        item_errors = @order.operations.map do |op|
          op.item.tap { |i| i.count_reserved += op.shift.abs }
          next if op.item.save

          op.item.errors.full_messages
        end

        if item_errors.any?
          error[:full_message] = error[:full_message].to_s + item_errors.flatten.compact.join('. ')
          raise ActiveRecord::RecordNotSaved
        end
      end
    end
  end
end
