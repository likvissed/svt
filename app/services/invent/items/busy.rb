module Invent
  module Items
    # Показать список техники, используемой на РМ в данный момент. В выборку не попадает техника, с которой имеются
    # связанные не закрытые ордеры
    class Busy < Invent::ApplicationService
      def initialize(type_id, invent_num, item_id, division = nil)
        @type_id = type_id
        @invent_num = invent_num
        @item_id = item_id
        @division = division
      end

      def run
        return false if @invent_num.blank? && @item_id.blank?
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
        @data = Item
                  .includes(:model, :type)
                  .select('invent_item.*, io_id')
                  .joins(
                    'LEFT OUTER JOIN
                    (
                      SELECT
                        warehouse_inv_item_to_operations.id AS io_id, warehouse_inv_item_to_operations.operation_id, warehouse_inv_item_to_operations.invent_item_id, op.id as op_id, op.status
                      FROM
                        warehouse_inv_item_to_operations
                      INNER JOIN
                        (SELECT * FROM warehouse_operations WHERE status != 2) op
                      ON op.id = warehouse_inv_item_to_operations.operation_id
                    ) io
                    ON
                      io.invent_item_id = invent_item.item_id'
                  )
                  .joins(workplace: :workplace_count)
                  .by_invent_num(@invent_num)
                  .by_item_id(@item_id)
                  .by_division(@division)
                  .where('invent_item.workplace_id IS NOT NULL')
                  .where('io_id IS NULL')
                  .by_type_id(@type_id)
      end

      def prepare_params
        @data = data.as_json(include: %i[model type], methods: :get_item_model).each do |item|
          item[:main_info] = item['invent_num'].blank? ? 'Инв. № отсутствует' : "Инв. №: #{item['invent_num']}"
        end
      end
    end
  end
end
