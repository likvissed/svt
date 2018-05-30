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
        new_params = @order_params['operations_attributes'].map do |op|
          op['inv_items_attributes'].map { |inv_item| { item_id: inv_item['id'], invent_num: inv_item['invent_num'] } }
        end.flatten

        @data = IO.popen("php #{Rails.root}/lib/generate_order_report.php #{Rails.env} #{@order_id} '#{new_params.to_json}'")
      end
    end
  end
end
