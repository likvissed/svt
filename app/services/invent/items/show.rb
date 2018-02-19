module Invent
  module Items
    # Загрузить данные по указанной технике
    class Show < Invent::ApplicationService
      def initialize(item_id)
        @item_id = item_id
      end

      def run
        @data = Item.includes(property_values: [:property, :property_list]).find(@item_id)
                  .as_json(
                    include: {
                      property_values: {
                        include: [:property, :property_list]
                      }
                    },
                    methods: :get_item_model
                  )

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end
    end
  end
end
