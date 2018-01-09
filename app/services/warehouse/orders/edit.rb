module Warehouse
  module Orders
    class Edit < BaseService
      def initialize(order_id)
        @data = {}
        @order_id = order_id
      end

      def run
        load_order
        load_divisions
        load_types
        load_users
        transform_to_json

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_order
        data[:order] = Order.includes(item_to_orders: { inv_item: %i[model type] }).find(@order_id)
      end

      def load_divisions
        data[:divisions] = Invent::WorkplaceCount.pluck(:division).sort_by(&:to_i)
      end

      def load_users
        data[:users] = UserIss.select(:id_tn, :fio).where(dept: data[:order].consumer_dept)
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_types
        data[:eq_types] = Invent::Type.where('name != "unknown"')
      end

      def transform_to_json
        data[:order] = data[:order].as_json(
          include: {
            item_to_orders: {
              include: {
                inv_item: {
                  include: %i[model type]
                }
              }
            }
          }
        )
        data[:order]['item_to_orders_attributes'] = data[:order]['item_to_orders']
        data[:order].delete('item_to_orders')

        data[:order]['item_to_orders_attributes'].each do |io|
          io['id'] = io['warehouse_item_to_order_id']
          io['inv_item']['add_info'] = get_model(io['inv_item'])

          io.delete('warehouse_item_to_order_id')
        end
      end
    end
  end
end
