module Warehouse
  module Supplies
    # Загрузить список склада
    class Edit < BaseService
      def initialize(current_user, supply_id)
        @current_user = current_user
        @supply_id = supply_id

        super
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
        data[:supply] = Supply.includes(operations: { item: :location }).find(@supply_id)

        authorize data[:supply], :edit?
        data[:operation] = Operation.new(operationable: data[:supply], shift: 0)
      end

      def load_types
        data[:eq_types] = Invent::Type.all
      end

      def transform_to_json
        data[:supply] = data[:supply].as_json(
          include: {
            operations: {
              include: {
                item: {
                  include: :location
                }
              }
            }
          }
        )

        data[:supply]['operations_attributes'] = data[:supply]['operations']
        data[:supply]['operations_attributes'].each do |op|
          next if op['item'].blank?

          op['item']['assign_barcode'] = Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op['item']['item_type'].to_s.downcase) ? true : false
        end
        data[:supply].delete('operations')

        # data[:supply]['date'] = data[:supply]['date'].strftime("%Y-%m-%d")
      end
    end
  end
end
