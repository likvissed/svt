module Warehouse
  module Orders
    # Создание приходного ордера
    class CreateIn < BaseService
      def initialize(current_user, order_params)
        @current_user = current_user
        @order_params = order_params
        @orders_arr = []

        super
      end

      def run
        raise 'Неверные данные (тип операции или аттрибут :shift)' unless order_in?

        processing_nested_attributes if @order_params['operations_attributes']&.any?
        return false unless wrap_order_with_transactions

        @order_state.broadcast_data

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def processing_nested_attributes
        # Массив id возвращаемой техники (с инв. номером)
        item_id_arr = @order_params['operations_attributes'].map { |op_attr| op_attr['inv_item_ids'] }.flatten.compact
        # Массив операций без инв. номера
        op_without_id_arr = @order_params['operations_attributes'].select { |op_attr| (!op_attr['inv_item_ids'] || op_attr['inv_item_ids'].compact.empty?) && !op_attr['w_item_id'] }
        # Массив операций без инв. номера и с назначенным штрих-кодом
        op_without_id_barcode_arr = @order_params['operations_attributes'].map { |op_attr| op_attr['w_item_id'] }.flatten.compact

        # Массив объектов возвращаемой техники
        items = Invent::Item.includes(workplace: :workplace_count).find(item_id_arr)

        new_params = generate_new_params(items)

        if op_without_id_arr.any?
          order_with_empty_op = @order_params.deep_dup
          order_with_empty_op['operations_attributes'] = op_without_id_arr
          new_params << order_with_empty_op
        end

        # Назначить технику со штрих-кодом для операции
        # Сначала необхоимо добавить в new_params свойства техники, а затем саму технику (generate_new_params)
        # для ситуаций, когда  нажимается кнопка "Создать и исполнить" приходный ордер,
        # чтобы свойство техники смогло назначить ID РМ, т.к. связь между ними в этом случае еще будет существовать
        if op_without_id_barcode_arr.any?

          # Массив объектов техники, в которых имеются операции без инв. номера и с назначенным штрих-кодом
          items_for_w_item = Barcode.where(codeable_id: op_without_id_barcode_arr, codeable_type: 'Warehouse::Item').map(&:codeable).map(&:item)
          # Если в позицию добавили технику без инв.№ и со штрих-кодом, но в другом окне уже отправили на склад
          # проверка, существует ли связь между w_item и invent_item
          if items_for_w_item.compact.present?
            items_for_w_item.uniq(&:workplace_id).each do |inv_item|
              order = @order_params.deep_dup
              order['operations_attributes'] = order['operations_attributes'].select do |op_attr|
                next unless op_attr['w_item_id']

                op_attr['item_id'] = op_attr['w_item_id']

                items_for_w_item.select { |i| i['workplace_id'] == inv_item.workplace_id }.map(&:item_id).include?(Item.find_by(id: op_attr['w_item_id']).item.item_id)
              end

              new_params.unshift order
            end
          end
        end

        @order_params = new_params.compact
      end

      def generate_new_params(items)
        items.uniq(&:workplace_id).map do |item|
          order = @order_params.deep_dup
          # Выбор операций для текущего РМ из полученного массива операций
          order['operations_attributes'] = order['operations_attributes'].select do |op_attr|
            next unless op_attr['inv_item_ids']

            items.select { |i| i['workplace_id'] == item.workplace_id }.map(&:item_id).include?(op_attr['inv_item_ids'].first)
          end
          order
        end
      end

      def wrap_order_with_transactions
        Item.transaction do
          begin
            Array.wrap(@order_params).each do |param|
              @location_for_w_items = create_array_location_for_items(param['operations_attributes']) if param['operations_attributes'].present?

              init_order(param)

              return false unless fill_order_arr
            end

            save_orders
            @data = @orders_arr.size

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

      def init_order(param)
        @order = Order.new(param)
        authorize @order, :create_in?
        @order_state = @order.done? && @order.dont_calculate_status ? Orders::In::DoneState.new(@order) : Orders::In::ProcessingState.new(@order)

        # Если ордер сразу создается и исполняется, проверить существует ли связь между inv_item и warehouse_item
        @order.execute_in = true if @order.dont_calculate_status

        @order.set_creator(current_user)

        @order_state.processing_operations(current_user)
      end

      def fill_order_arr
        @order.transaction(requires_new: true) do
          begin
            find_or_create_warehouse_items
            assiged_location_for_w_items(@location_for_w_items) if @location_for_w_items.present?
            @orders_arr << @order

            true
          rescue ActiveRecord::RecordNotSaved
            raise ActiveRecord::Rollback
          end
        end
      end

      def find_or_create_warehouse_items
        @order.operations.each do |op|
          if op.inv_items.any?
            op.inv_items.each { |inv_item| warehouse_item_in(inv_item) }
          else
            @order_state.init_warehouse_item(op)
          end
        end
      end

      def save_orders
        Invent::Item.transaction(requires_new: true) do
          @orders_arr.each do |order|
            save_order(order)

            @order_state.update_inv_items(order, current_user.access_token)
          end
        end
      end
    end
  end
end
