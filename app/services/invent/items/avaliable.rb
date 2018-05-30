module Invent
  module Items
    # Загрузить список свободной Б/У техники указанного типа
    class Avaliable < Invent::ApplicationService
      def initialize(type_id)
        @type_id = type_id

        super
      end

      def run
        load_items
        prepare_params

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def load_items
        @items = Item.includes(:model).where(workplace: nil, type_id: @type_id)
      end

      def prepare_params
        @data = @items.as_json(include: :model, methods: :get_item_model).each do |item|
          item[:main_info] = item['invent_num'].blank? ? 'Инв. № отсутствует' : "Инв. №: #{item['invent_num']}"
        end
      end
    end
  end
end
