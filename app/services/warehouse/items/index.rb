module Warehouse
  module Items
    # Загрузить список склада
    class Index < Warehouse::ApplicationService
      def initialize(params)
        @params = params
        @start = params[:start].to_i
        @length = params[:length].to_i
        @selected_order_id = params[:selected_order_id]

        super
      end

      def run
        load_order_items
        load_other_items
        init_filters if need_init_filters?
        init_order unless @selected_order_id
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

      def load_order_items
        # Список всех items, которые принадлежат ордеру
        @order_items = @selected_order_id ? Order.find(@selected_order_id).items.includes(:inv_item) : []
        # Список items ордера, который будет соответствовать текущей странице
        @order_items_to_result = small_order? ? @order_items : @order_items.limit(@length).offset(@start)
        # Список items ордера, который необходимо исключить из выборки items (которая будет далее)
        @exclude_items = @order_items
      end

      def load_other_items
        data[:recordsTotal] = Item.count
        @items = Item.all
        run_filters if params[:filters]
      end

      def run_filters
        @items = @items.filter(filtering_params)
      end

      def filtering_params
        JSON.parse(params[:filters]).slice('show_only_presence', 'used', 'item_type', 'barcode', 'item_model')
      end

      def limit_records
        data[:recordsFiltered] = @items.count

        if first_page_after_order_items?
          limit = @length - @order_items_to_result.size
          start = 0
        elsif order_for_all_page?
          limit = @length - @order_items_to_result.size
          start = @start
        else
          limit = @length
          start = @start - @order_items_to_result.size
        end

        @items = @items.includes(:inv_item, :supplies).where.not(id: @exclude_items.map(&:id)).order(id: :desc).limit(limit).offset(start)
      end

      def prepare_to_render
        result_arr = if first_page_after_order_items? || order_for_all_page?
                       @order_items_to_result + @items
                     else
                       @items
                     end

        data[:data] = result_arr.as_json(include: %i[inv_item supplies]).each do |item|
          item['translated_used'] = item['used'] ? '<span class="label label-warning">Б/У</span>' : '<span class="label label-success">Новое</span>'
          item['supplies'].each { |supply| supply['date'] = supply['date'].strftime('%d-%m-%Y') }
        end
      end

      def init_order
        new_order = Orders::NewOrder.new(nil, :out)

        raise 'Не удалось создать шаблон расходного ордера' unless new_order.run

        data[:order] = new_order.data
      end

      def init_filters
        data[:filters] = {}
        data[:filters][:item_types] = Item.pluck(:item_type).uniq
      end

      def load_orders
        order = Orders::Index.new({ start: nil, length: nil }, operation: :out, status: :processing)

        raise 'Не удалось загрузить список ордеров' unless order.run

        data[:orders] = order.data[:data]
        data[:orders].each { |o| o[:main_info] = "ID ордера: #{o['id']}; ID РМ: #{o['invent_workplace_id']}" }
      end

      # true - если размер ордера меньше, чем число items на странице
      def small_order?
        @order_items.size < @length
      end

      # Проверка, займут ли items ордера текущую страницу целиком (true - если займут)
      def order_for_all_page?
        # Если >= 0 - число items ордера займет целую страницу
        # Если < 0 - число items ордера не займет целую страницу
        !(@order_items.size - @start - @length).negative?
      end

      # Проверка, содержит ли выбранная страница технику, принадлежащую к ордеру
      def first_page_after_order_items?
        tmp = @order_items.size - @start
        tmp < @length && tmp.positive?
      end
    end
  end
end
