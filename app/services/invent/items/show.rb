module Invent
  module Items
    # Загрузить данные по указанной технике
    class Show < Invent::ApplicationService
      def initialize(condition)
        @condition = condition

        super
      end

      def run
        @data = Item.includes(:type, :model, property_values: %i[property property_list])
                  .by_item_id(@condition[:item_id])
                  .by_invent_num(@condition[:invent_num])
                  .by_type_id(@condition[:type_id])
                  .limit(Item::RECORD_LIMIT)
                  .as_json(
                    include: {
                      property_values: {
                        include: %i[property property_list]
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
