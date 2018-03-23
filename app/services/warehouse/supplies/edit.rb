module Warehouse
  module Supplies
    # Загрузить список склада
    class Edit < BaseService
      def initialize(supply_id)
        @data = {}
        @supply_id = supply_id
      end

      def run
        load_supply
        load_types
        transform_to_json

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_supply
        data[:supply] = Supply.includes(operations: :item).find(@supply_id)
        data[:operation] = Operation.new(operationable: data[:supply], shift: 0)
      end

      def load_types
        data[:eq_types] = Invent::Type.where('name != "unknown"')
      end

      def transform_to_json
        data[:supply] = data[:supply].as_json(
          include: {
            operations: {
              include: :item
            }
          }
        )

        data[:supply]['operations_attributes'] = data[:supply]['operations']
        data[:supply].delete('operations')

        # data[:supply]['date'] = data[:supply]['date'].strftime("%Y-%m-%d")
      end
    end
  end
end
