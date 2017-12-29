module Warehouse
  module Orders
    # Инициализация объекта Order
    class NewOrder < BaseService
      def initialize(operation)
        @data = {}
        @operation = operation
      end

      def run
        init_order
        load_divisions
        load_types

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def init_order
        data[:order] = Order.new(operation: @operation)
        data[:operation] = data[:order].operations.build(shift: 1)
      end

      def load_divisions
        data[:divisions] = Invent::WorkplaceCount.pluck(:division).sort_by(&:to_i)
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_types
        data[:eq_types] = Invent::Type.where('name != "unknown"')
      end
    end
  end
end
