module Warehouse
  module Orders
    # Изменение приходного ордера
    class UpdateIn < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params.to_h

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_in?

        @order = Order.find(@order_id)
        authorize @order, :update_in?
        @order_state = Orders::In::ProcessingState.new(@order)
        return false unless wrap_order_with_transactions

        broadcast_items
        broadcast_in_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def wrap_order_with_transactions
        operations = @order_params['operations_attributes']

        if operations.present?
          @location_for_w_items = create_array_location_for_items(operations)

          # Массив id техники, у которой необходимо удалить расположение
          @array_delete_location = []
          operations.each { |op| @array_delete_location.push(op['inv_item_ids'].first) if op['_destroy'] == 1 && op['inv_item_ids'].present? }
        end

        assign_order_params

        Item.transaction do
          begin
            find_or_create_warehouse_items

            Invent::Item.transaction(requires_new: true) do
              update_inv_items
              save_order(@order)

              assiged_location_for_w_items(@location_for_w_items) if @location_for_w_items.present?
              delete_location_for_w_items if @array_delete_location.present?
            end

            true
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          rescue ActiveRecord::RecordNotDestroyed
            process_order_errors(@order, true)

            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def assign_order_params
        @order.assign_attributes(@order_params)
        @order.set_creator(current_user)
      end

      def find_or_create_warehouse_items
        @order.operations.each do |op|
          next if op.id || op.marked_for_destruction?

          op.inv_items.each { |inv_item| warehouse_item_in(inv_item) }
        end
      end

      def update_inv_items
        return unless @order.inv_workplace

        @order.operations.each do |op|
          if op.new_record?
            op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_bring) }
          elsif op._destroy
            op.inv_items.each { |inv_item| inv_item.update!(status: :in_workplace) }
          end
        end
      end

      def delete_location_for_w_items
        @array_delete_location.each do |id|
          w_item = Item.find_by(invent_item_id: id)

          w_item.location.destroy
          w_item.update(location_id: 0)
        end
      end
    end
  end
end
