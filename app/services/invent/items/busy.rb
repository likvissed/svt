module Invent
  module Items
    # Показать список техники, используемой на РМ в данный момент
    class Busy < Invent::ApplicationService
      def initialize(type_id, invent_num = '')
        @type_id = type_id
        @invent_num = invent_num
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
        @items = Item.includes(:model, :type).by_invent_num(@invent_num).where('workplace_id IS NOT NULL').where(type_id: @type_id)
      end

      def prepare_params
        @data = @items.as_json(include: %i[model type], methods: :get_item_model).each do |item|
          item[:main_info] = item['invent_num'].blank? ? 'Инв. № отсутствует' : "Инв. №: #{item['invent_num']}"
        end
      end
    end
  end
end
