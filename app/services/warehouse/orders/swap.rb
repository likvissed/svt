module Warehouse
  module Orders
    # Создание приходящего и исходящего ордера (случаи, когди техника переносится из РМ в РМ в рамках отдела)
    class Swap < BaseService
      def initialize(current_user, new_workplace_id, inv_item_ids)
        @current_user = current_user
        @new_workplace_id = new_workplace_id
        @inv_item_ids = inv_item_ids

        super
      end

      def run
        find_workplace
        find_inv_items
        return false unless wrap_in_orders
        return false unless wrap_out_orders

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_workplace
        @workplace = Invent::Workplace.find(@new_workplace_id)
      end

      def find_inv_items
        @inv_items_obj = Invent::Item.includes(workplace: :workplace_count).find(@inv_item_ids).group_by(&:workplace_id)
      end

      def wrap_in_orders
        Item.transaction do
          begin
            Order.transaction(requires_new: true) do
              Invent::Item.transaction(requires_new: true) do
                @inv_items_obj.each_value { |inv_items| create_in_order(inv_items) }
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

      def create_in_order(inv_items)
        init_order(:in)

        inv_items.each do |inv_item|
          op = @order.operations.build(
            shift: 1,
            status: :done,
            item_type: inv_item.type.short_description,
            item_model: inv_item.full_item_model
          )
          op.set_stockman(current_user)
          op.inv_item_ids = [inv_item.item_id]

          # Добавление операции в приходный ордер для свойств техники, если они имеются
          inv_item.warehouse_items.each do |w_item|
            op = @order.operations.build(
              shift: 1,
              status: :done,
              item_type: w_item.item_type,
              item_model: w_item.item_model,
              item_id: w_item.id
            )
            op.set_stockman(current_user)
          end

          warehouse_item_in(inv_item)
        end

        save_order(@order)
        @order.operations.each { |op| op.inv_items.each { |inv_item| inv_item.update!(status: :in_stock, workplace: nil) } }
      end

      def wrap_out_orders
        Order.transaction do
          begin
            Item.transaction(requires_new: true) do
              Invent::Item.transaction(requires_new: true) do
                @inv_items_obj.each_value { |inv_items| create_out_order(inv_items) }
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

      def create_out_order(inv_items)
        init_order(:out)

        inv_items.each do |inv_item|
          op = @order.operations.build(
            item: inv_item.warehouse_item,
            shift: -1,
            status: :done,
            item_type: inv_item.type.short_description,
            item_model: inv_item.full_item_model
          )
          op.set_stockman(current_user)
          op.inv_item_ids = [inv_item.item_id]
          op.calculate_item_count

          # Добавление операции в расходный ордер для свойств техники
          inv_item.warehouse_items.each do |w_item|
            op = @order.operations.build(
              shift: -1,
              status: :done,
              item_type: w_item.item_type,
              item_model: w_item.item_model,
              item_id: w_item.id
            )
            op.set_stockman(current_user)
            op.inv_item_ids = [inv_item.item_id]
          end
        end

        save_order(@order)
        @order.operations.each do |op|
          op.inv_items.each { |inv_item| inv_item.update!(status: :in_workplace, workplace: @workplace) }
          op.item.save!
        end
      end

      def init_order(operation)
        @order = Order.new(
          inv_workplace: @workplace,
          consumer_id_tn: @workplace.id_tn,
          operation: operation,
          skip_validator: true
        )
        @order.set_creator(current_user)
        @order_state = Orders::In::DoneState.new(@order)
      end
    end
  end
end
