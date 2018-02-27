module Warehouse
  module Orders
    # Загрузить список ордеров
    class Index < BaseService
      def initialize(params)
        @data = {}
        @start = params[:start]
        @length = params[:length]
      end

      def run
        load_orders
        limit_records
        prepare_to_render

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_orders
        data[:recordsTotal] = Order.count
        @orders = Order.all
      end

      def limit_records
        data[:recordsFiltered] = @orders.count
        @orders = @orders.includes(:operations, :creator, :consumer, :validator).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @orders.as_json(include: %i[creator consumer validator], methods: :operations_to_string).each do |order|
          order['status_translated'] = Order.translate_enum(:status, order['status'])
          order['operation_translated'] = Order.translate_enum(:operation, order['operation'])
        end
      end
    end
  end
end
