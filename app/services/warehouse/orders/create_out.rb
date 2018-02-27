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
        broadcast_workplaces

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_params
        # Все задействованные элементы склада
        items = Item.includes(:inv_item).where(id: @order_params['operations_attributes'].map { |op| op['item_id'] }.compact)
        # Массив объектов выдаваемой новой техники (с инв. номером)
        items_new = items.where(invent_item_id: nil, warehouse_type: :with_invent_num)
        # Массив объектов выдаваемой б/у техники (с инв. номерами)
        items_old = items.where('invent_item_id IS NOT NULL').where(warehouse_type: :with_invent_num)

        @order_params['operations_attributes'].each do |op|
          if item_new = items_new.find { |item| item.id == op['item_id'] }
            op['inv_items_attributes'] = op['shift'].abs.times.map do
              invent_item = Invent::Item.new(
                type: item_new.inv_type,
                workplace_id: @order_params['workpalce_id'],
                model: item_new.inv_model,
                item_model: item_new.item_model,
                invent_num: nil,
                serial_num: nil,
                status: :waiting_take
              ).as_json
              invent_item['property_values_attributes'] = init_property_values(item_new)
              invent_item
            end
          elsif item_old = items_old.find { |item| item.id == op['item_id'] }
            op['inv_item_ids'] = [item_old.invent_item_id]
          end
        end
      end

      def init_order
        @order = Order.new(@order_params)
        @order.set_creator(current_user)
      end

      def wrap_order
        Invent::Item.transaction do
          begin
            @order.operations.each do |op|
              op.inv_items.each { |inv_item| inv_item.update!(status: :waiting_take, workplace: @order.inv_workplace, disable_filters: true) }
            end

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

      def init_property_values(item)
        item.inv_type.properties.map do |prop|
          prop_list = if item.inv_model && %w[list list_plus].include?(prop.property_type)
                        item.inv_model.model_property_lists.find_by(property: prop).property_list
                      else
                        nil
                      end

          Invent::PropertyValue.new(
            property: prop,
            property_list: prop_list,
            value: ''
          ).as_json
        end
      end
    end
  end
end
