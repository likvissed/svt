module Warehouse
  module Orders
    class Print < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = JSON.parse(order_params)

        super
      end

      def run
        raise 'Операции отсутствуют' unless @order_params['operations_attributes']

        find_order
        generate_report

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.find(@order_id)
        authorize @order, :print?
      end

      def generate_report
        # Массив id позиций, которые относятся к технике без инв. №
        warehouse_item_params = @order_params['operations_attributes'].select { |op| op['inv_items_attributes'].blank? && op['inv_item_ids'].blank? }.map { |op| op['id'] }

        date = @order.done? ? @order.closed_time : Time.zone.now
        l_date = I18n.l(date, format: '%d %B %Y')

        # Получение точно действительного токена
        UsersReference.new_token_hr

        report = Rails.root.join('lib', 'generate_order_report.php')
        command = "php #{report} #{Rails.env} #{@order_id} '#{@order_params['consumer_fio'] || @order_params['consumer_tn']}' '#{l_date}' '#{invent_item_params.to_json}' '#{warehouse_item_params.to_json}' '#{Rails.cache.read('token_hr')}'  '#{ENV['USERS_REFERENCE_URI_SEARCH']}'"
        @data = IO.popen(command)
      end

      def invent_item_params
        @order_params['operations_attributes'].map do |op|
          if op['inv_items_attributes']
            op['inv_items_attributes'].map { |inv_item| generate_invent_item_obj(inv_item['id'], inv_item['invent_num'], inv_item['serial_num']) }
          elsif op['inv_item_ids']
            op['inv_item_ids'].map { |inv_item_id| generate_invent_item_obj(inv_item_id) }
          end
        end.flatten.compact
      end

      def generate_invent_item_obj(id, invent_num = '', serial_num = '')
        {
          item_id: id,
          invent_num: invent_num,
          serial_num: serial_num
        }
      end
    end
  end
end
