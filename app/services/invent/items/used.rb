module Invent
  module Items
    # Загрузить список Б/У техники указанного типа
    class Used < ApplicationService
      def initialize(type_id)
        @type_id = type_id
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
        @items = Item.includes(:model).where(workplace: nil, type_id: @type_id).as_json(include: :model)
      end

      def prepare_params
        @data = @items.each do |item|
          item[:main_info] = item['invent_num'].blank? ? 'Инв. № отсутствует' : "Инв. №: #{item['invent_num']}"
          item[:add_info] = get_model(item)
        end
      end
    end
  end
end
