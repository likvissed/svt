module Warehouse
  module Items
    # Загрузить список склада
    class Index < Warehouse::ApplicationService
      def initialize(params)
        @data = {}
        @start = params[:start]
        @length = params[:length]
      end

      def run
        load_items
        init_order
        load_orders
        limit_records
        prepare_to_render

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_items
        data[:recordsTotal] = Item.count
        @items = Item.all
      end

      def limit_records
        data[:recordsFiltered] = @items.count
        @items = @items.includes(:inv_item).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @items.as_json(include: :inv_item).each do |item|
          item['translated_used'] = item['used'] ? 'Б/У' : 'Новое'
        end
      end

      def init_order
        new_order = Orders::NewOrder.new(:out)

        if new_order.run
          data[:order] = new_order.data
        else
          raise 'Не удалось создать шаблон расходного ордера'
        end
      end

      def load_orders
        order = Orders::Index.new({ start: nil, length: nil }, { operation: :out, status: :processing })
        if order.run
          data[:orders] = order.data[:data]

          data[:orders].each do |order|
            order[:main_info] = "ID ордера: #{order['id']}; ID РМ: #{order['invent_workplace_id']}"
          end
        else
          raise 'Не удалось загрузить список ордеров'
        end
      end
    end
  end
end
