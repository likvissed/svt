module Warehouse
  module Orders
    # Инициализация объекта Order
    class NewOrder < BaseService
      def initialize(current_user, operation)
        @current_user = current_user
        @operation = operation.to_sym

        super
      end

      def run
        init_order
        load_divisions
        load_types if @operation == :in

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def init_order
        data[:order] = Order.new(operation: @operation)
        authorize data[:order], :new? if current_user

        shift = @operation == :in ? 1 : -1
        data[:operation] = data[:order].operations.build(shift: shift)
      end

      def load_divisions
        data[:divisions] = Invent::WorkplaceCount.pluck(:division).sort_by(&:to_i)
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_types
        data[:eq_types] = Invent::Type.all
      end
    end
  end
end
