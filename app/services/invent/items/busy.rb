module Invent
  module Items
    # Показать список техники, используемой на РМ в данный момент. В выборку не попадает техника, с которой имеются
    # связанные не закрытые ордеры
    class Busy < Invent::ApplicationService
      def initialize(type_id, invent_num)
        @type_id = type_id
        @invent_num = invent_num
      end

      def run
        return false if @invent_num.blank?
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
        ids = Warehouse::Order.includes(:item_to_orders).where(status: :processing)
                .map { |order| order.item_to_orders.pluck(:invent_item_id) }.flatten
        @data = Item.includes(:model, :type).by_invent_num(@invent_num).where('workplace_id IS NOT NULL')
                   .where(type_id: @type_id).where.not(item_id: ids)
      end

      def prepare_params
        @data = data.as_json(include: %i[model type], methods: :get_item_model).each do |item|
          item[:main_info] = item['invent_num'].blank? ? 'Инв. № отсутствует' : "Инв. №: #{item['invent_num']}"
        end
      end
    end
  end
end
