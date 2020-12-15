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

        data[:items] = find_item_by_bacrode if @item_barcode.present?
        data[:items] = find_item_by_invent_num if @invent_num.present?

        item_not_found if data[:items].empty?

        exclude_items_in_order
      end

      def item_not_found
        errors.add(:base, :item_not_found)
        raise 'Техника не найдена'
      end

      # Поиск техники по штрих-коду (warehouse_item или invent_item)
      def find_item_by_bacrode
        barcode = Barcode.find_by(id: @item_barcode)

        return [] if barcode.blank?
        item = barcode.codeable

        # Исключаем вывод техники, которая находится на складе,
        # т.е. не имеет связь с inv_item для warehouse_item
        return [] if barcode.codeable_type == 'Warehouse::Item' && item.item.blank?
        # т.е. не имеет рабочего места, для invent_item
        return [] if barcode.codeable_type == 'Invent::Item' && item.workplace.nil?

        Array.wrap(item)
      end

      # Поиск техники по инвентарному номеру или по отделу (только invent_item)
      def find_item_by_invent_num
        item = Item
                 .includes(:model, :type, :property_values)
                 .select('invent_item.*')
                 .joins(workplace: :workplace_count)
                 .by_invent_num(@invent_num)
                 .by_division(@division)
                 .where('invent_item.workplace_id IS NOT NULL')
                 .by_type_id(@type_id)

        Array.wrap(item)
      end

      def exclude_items_in_order
        # Техника, которая используется в незакрытых ордерах
        excluded = []
        # Список незакрытых ордеров
        orders = []
        data[:items].each do |item|
          if item.class.name == 'Invent::Item'
            item.warehouse_inv_item_to_operations.find_each do |io|
              next if io.operation.done?

              excluded << item
              orders << io.operation.operationable.id
              break
            end

          elsif item.class.name == 'Warehouse::Item'
            item.operations.each do |op|
              next if op.done?

              excluded << item
              orders << op.operationable.id
              break
            end
          end
        end

        data[:items] -= excluded

        return if data[:items].any?

        errors.add(:base, :item_already_used_in_orders, orders: orders.join(', '))
        raise 'Техника используется в ордерах'
      end

      def prepare_params
        data[:items] = data[:items].map do |item|
          if item.class.name == 'Invent::Item'
            item = item.as_json(
              include: [
                :model,
                :type,
                warehouse_items: { include: :operations }
              ],
              methods: :full_item_model
            )

            inv_num = item['invent_num'].blank? ? 'инв. № отсутствует' : "инв. №: #{item['invent_num']}"
            item[:main_info] = "#{item['type']['short_description']} - #{inv_num}"
            item[:codeable_type] = 'invent'
            item[:warehouse_items] = item['warehouse_items'].map do |w_item|
              operation_done = true

              # Проверить в связанной техники, если ли незакрытые ордеры
              w_item['operations'].each { |op| operation_done = false if op['status'] == 'processing' }

              # Для того, чтобы свойство было добавлено в позиции вместе с выбранной техникой
              w_item['codeable_type'] = 'warehouse'
              operation_done ? w_item : nil
            end.compact
            item
          elsif item.class.name == 'Warehouse::Item'
            item = item.as_json(include: :item)

            item[:main_info] = "#{item['item_type']} - #{item['item_model']}"
            item[:codeable_type] = 'warehouse'
            item
          end
        end
      end
    end
  end
end
