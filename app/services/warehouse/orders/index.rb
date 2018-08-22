module Warehouse
  module Orders
    # Загрузить список ордеров
    class Index < BaseService
      def initialize(params, **order_conditions)
        @params = params
        @order_conditions = order_conditions

        super
      end

      def run
        load_orders
        limit_records
        init_filters if need_init_filters?
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
        @orders = Order.where(@order_conditions)
        run_filters if params[:filters]
      end

      def run_filters
        @orders = @orders.filter(filtering_params)
      end

      def filtering_params
        JSON.parse(params[:filters]).slice('consumer_dept', 'operation', 'creator_fio', 'consumer_fio')
      end

      def limit_records
        data[:recordsFiltered] = @orders.count
        @orders = @orders
                    .includes(:operations, :creator, :consumer, :validator)
                    .order(id: :desc).limit(params[:length]).offset(params[:start])
      end

      def prepare_to_render
        data[:data] = @orders.as_json(include: %i[creator consumer validator], methods: :operations_to_string).each do |order|
          order['status_translated'] = Order.translate_enum(:status, order['status'])
          order['operation_translated'] = Order.translate_enum(:operation, order['operation'])
          order['closed_time'] = order['closed_time'].strftime('%d-%m-%Y %H:%M:%S') if order['closed_time']
        end
      end

      def init_filters
        data[:filters] = {}
        data[:filters][:divisions] = Invent::WorkplaceCount.select(:workplace_count_id, :division).order('CAST(division AS SIGNED)')
        data[:filters][:operations] = Order.operations.map { |key, _val| [key, Order.translate_enum(:operation, key)] }.to_h
      end
    end
  end
end
