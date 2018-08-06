module Warehouse
  module Supplies
    # Загрузить список склада
    class Index < BaseService
      def initialize(params)
        @params = params

        super
      end

      def run
        load_supplies
        limit_records
        prepare_to_render

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_supplies
        data[:recordsTotal] = Supply.count
        @supplies = Supply.all.includes(:operations)
      end

      def limit_records
        data[:recordsFiltered] = @supplies.count
        @supplies = @supplies.order(id: :desc).limit(params[:length]).offset(params[:start])
      end

      def prepare_to_render
        data[:data] = @supplies.as_json(include: :operations).each do |item|
          item['total_count'] = item['operations'].inject(0) { |sum, op| sum + op['shift'] }
          item['date'] = item['date'].strftime('%d-%m-%Y') if item['date']
        end
      end
    end
  end
end
