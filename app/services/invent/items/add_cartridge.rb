module Invent
  module Items
    class AddCartridge < Invent::ApplicationService
      def initialize(current_user, cartridge)
        @current_user = current_user
        @cartridge = cartridge

        @comment = '/* Создано автоматически системой с РМ */'

        super
      end

      def run
        find_item

        create_and_execute_in_order
        create_out
        execute_out

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        @inv_item = Item.find(@cartridge[:item_id])

        return unless @inv_item.status != 'in_workplace' || @inv_item.workplace.blank?

        mess_err = I18n.t('activemodel.errors.models.invent/items/add_cartridge.item_status_not_in_workplace')

        error[:full_message] = mess_err
        raise mess_err
      end

      # Создание и исполнение приходного ордера, т.е. создание картриджа на складе
      def create_and_execute_in_order
        # Создание приходного ордера
        new_order = Warehouse::Orders::NewOrder.new(@current_user, 'in')
        new_order.run
        new_order_params = new_order.data[:order].as_json

        # Параметры ордера
        new_order_params['invent_workplace_id'] = @inv_item.workplace_id
        new_order_params['consumer_id_tn'] = @inv_item.workplace.try(:id_tn)
        new_order_params['status'] = 'done'
        new_order_params['dont_calculate_status'] = true
        new_order_params['comment'] = @comment

        # Создание позиции ордера для каждого картриджа
        new_order_params['operations_attributes'] = []
        (1..@cartridge['count'].to_i).each do |_|
          op = new_order.data[:operation]
          op.item_type = 'Картридж'
          op.item_model = @cartridge['name_model']

          new_order_params['operations_attributes'] << op.as_json
        end

        # Присваиваем для создания расходного ордера
        @order_params = new_order_params

        create_in = Warehouse::Orders::CreateIn.new(@current_user, @order_params)
        if create_in.run
          # Созданный приходный ордер
          @order_in = create_in.instance_variable_get(:@order)
        else
          error[:full_message] = create_in.errors.instance_variable_get(:@base).instance_variable_get(:@error)[:full_message]
          raise 'Ордер :create_in не сохранен'
        end
      end

      def create_out
        @order = Warehouse::Order.find_by(id: @order_in.id)

        # Массив id техники со склада (Картридж)
        @items = @order.items.map { |w_item| w_item['id'] }.flatten

        @order_params['operation'] = 'out'
        @order_params['status'] = 'processing'
        @order_params['comment'] = @comment
        # Обязятельно присваиваем инв.№ печатной техники для ордера, чтобы картридж был создан с назначенным штрих-кодом
        @order_params['invent_num'] = @inv_item.invent_num

        @order_params['operations_attributes'].each_with_index do |op, index|
          op['shift'] = -1
          op['item_id'] = @items[index]
        end

        # Создание расходного ордера
        create_out = Warehouse::Orders::CreateOut.new(@current_user, @order_params)

        if create_out.run
          @order_out = create_out.instance_variable_get(:@order)
        else
          error[:full_message] = create_out.errors.instance_variable_get(:@base).instance_variable_get(:@error)[:full_message]
          raise 'Ордер :create_out не сохранен'
        end
      end

      def execute_out
        # Находим созданный расходный ордер, чтобы получить id каждой позиции для его исполнения
        order_out = Warehouse::Order.find_by(id: @order_out.id)

        @order_params = order_out.as_json

        # Пропуск ФИО кто утвердил ордер, тк работнику разрешено добавлять картридж на РМ
        @order_params['skip_validator'] = true

        @order_params['operations_attributes'] = order_out.operations.as_json
        @order_params['operations_attributes'].each { |op| op['status'] = 'done' }

        execute_out = Warehouse::Orders::ExecuteOut.new(@current_user, @order_out.id, @order_params)

        # Исполнение расходного ордера
        if execute_out.run
          @order_out = execute_out.instance_variable_get(:@order)
        else
          error[:full_message] = execute_out.errors.instance_variable_get(:@base).instance_variable_get(:@error)[:full_message]
          raise 'Ордер :execute_out не сохранен'
        end
      end
    end
  end
end
