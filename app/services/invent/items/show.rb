module Invent
  module Items
    # Загрузить данные по указанной технике
    class Show < Invent::ApplicationService
      def initialize(item_id)
        @item_id = item_id
      end

      def run
        load_item
        prepare_to_edit_item(data)

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def load_item
        @data = Item
                  .includes(property_values: :property)
                  .find(@item_id)
                  .as_json(include: { property_values: { include: :property } })

        data['status'] = :waiting_take
      end
    end
  end
end
