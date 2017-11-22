module Invent
  module Items
    class Used < ApplicationService
      def initialize(type_id)
        @type_id = type_id
      end

      def run
        load_items
        prepare_params

        true
      rescue StandardError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace.inspect

        false
      end

      private

      def load_items
        @items = InvItem.includes(:inv_model).where(workplace: nil, type_id: @type_id).as_json(include: :inv_model)
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
