module Invent
  module Items
    class Show < ApplicationService
      def initialize(item_id)
        @item_id = item_id
      end

      def run
        load_item
        prepare_to_edit_item(data)
      rescue RuntimeError
        false
      end

      private

      def load_item
        @data = InvItem
                  .includes(inv_property_values: :inv_property)
                  .find(@item_id)
                  .as_json(include: { inv_property_values: { include: :inv_property } })

        data['status'] = :waiting_take
      end
    end
  end
end
