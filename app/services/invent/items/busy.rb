module Invent
  module Items
    # Показать список техники, используемой на РМ в данный момент. В выборку не попадает техника, с которой имеются
    # связанные не закрытые ордеры
    class Busy < Invent::ApplicationService
      def initialize(type_id, invent_num, item_barcode, division = nil)
        @type_id = type_id
        @invent_num = invent_num
        @item_barcode = item_barcode
        @division = division

        super
      end

      def run
        item_not_found if @invent_num.blank? && @item_barcode.blank?

        find_items
        prepare_params

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def find_items
        # @data = Item
        #           .includes(:model, :type)
        #           .select('invent_item.*, io_id')
        #           .joins(
        #             'LEFT OUTER JOIN
        #             (
        #               SELECT
        #                 warehouse_inv_item_to_operations.id AS io_id, warehouse_inv_item_to_operations.operation_id, warehouse_inv_item_to_operations.invent_item_id, op.id as op_id, op.status
        #               FROM
        #                 warehouse_inv_item_to_operations
        #               INNER JOIN
        #                 (SELECT * FROM warehouse_operations WHERE status != 2) op
        #               ON op.id = warehouse_inv_item_to_operations.operation_id
        #             ) io
        #             ON
        #               io.invent_item_id = invent_item.item_id'
        #           )
        #           .joins(workplace: :workplace_count)
        #           .by_invent_num(@invent_num)
        #           .by_item_id(@item_id)
        #           .by_division(@division)
        #           .where('invent_item.workplace_id IS NOT NULL')
        #           .where('io_id IS NULL')
        #           .by_type_id(@type_id)

        data[:items] = Item
                         .includes(:model, :type, :property_values, :barcode_item)
                         .select('invent_item.*')
                         .joins(:barcode_item, workplace: :workplace_count)
                         .by_invent_num(@invent_num)
                         .by_division(@division)
                         .where('invent_item.workplace_id IS NOT NULL')
                         .by_type_id(@type_id)
                         .where('id = ? OR invent_num = ?', @item_barcode, @invent_num)

        item_not_found if data[:items].empty?

        exclude_items_in_order
      end

      def item_not_found
        errors.add(:base, :item_not_found)
        raise 'Техника не найдена'
      end

      def exclude_items_in_order
        # Техника, которая используется в незакрытых ордерах
        excluded = []
        # Список незакрытых ордеров
        orders = []
        data[:items].each do |item|
          item.warehouse_inv_item_to_operations.find_each do |io|
            next if io.operation.done?

            excluded << item
            orders << io.operation.operationable.id
            break
          end
        end

        data[:items] -= excluded

        return if data[:items].any?

        errors.add(:base, :item_already_used_in_orders, orders: orders.join(', '))
        raise 'Техника используется в ордерах'
      end

      def prepare_params
        data[:items] = data[:items].as_json(include: %i[model type barcode_item], methods: :full_item_model).each do |item|
          inv_num = item['invent_num'].blank? ? 'инв. № отсутствует' : "инв. №: #{item['invent_num']}"
          item[:main_info] = "#{item['type']['short_description']} - #{inv_num}"
        end
      end
    end
  end
end
