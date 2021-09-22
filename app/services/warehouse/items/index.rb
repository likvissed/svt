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
        init_filters
        load_orders
        limit_records
        load_locations
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
        JSON.parse(params[:filters]).slice('show_only_presence', 'status', 'item_type', 'barcode', 'item_model', 'invent_num', 'barcode_item', 'building_id', 'room_id')
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

        @items = @items.includes(:inv_type, :supplies, :location, :barcode_item, inv_item: :barcode_item).where.not(id: @exclude_items.map(&:id)).order(id: :desc).limit(limit).offset(start)
      end

      def load_locations
        data[:locations] = Invent::LkInvents::InitProperties.new(current_user).load_locations
      end

      def prepare_to_render
        result_arr = if first_page_after_order_items? || order_for_all_page?
                       @order_items_to_result + @items
                     else
                       @items
                     end

        data[:data] = result_arr.as_json(
          include: [
            :inv_type,
            :supplies,
            :location,
            :barcode_item,
            inv_item: { include: :barcode_item }
          ]
        ).each do |item|
          item['range_inv_nums'] = item['invent_num_end'].to_i.zero? ? '' : "#{item['invent_num_start']} - #{item['invent_num_end']}"

          item['barcode_item'] = if item['invent_item_id'].present? && item['inv_item'].present?
                                   item['inv_item']['barcode_item']['id']
                                 elsif item['barcode_item'].present?
                                   item['barcode_item']['id']
                                 end

          item['location_name'] = 'Не назначено'

          unless item['location'].nil?
            site = data[:locations].find { |location| location['site_id'] == item['location']['site_id'] }
            building = site['iss_reference_buildings'].find { |b| b['building_id'] == item['location']['building_id'] }
            room = building['iss_reference_rooms'].find { |b| b['room_id'] == item['location']['room_id'] }

            if room.present?
              item['location_name'] = "Пл. '#{site['short_name']}', корп. #{building['name']}, комн. #{room['name']}"
            end
          end

          i_tr = Item.translate_enum(:status, item['status'])
          item['translated_status'] = case item['status']
                                      when 'non_used'
                                        "<span class='label label-success'>#{i_tr}</span>"
                                      when 'used'
                                        "<span class='label label-warning'>#{i_tr}</span>"
                                      when 'waiting_write_off'
                                        "<span class='label label-danger'>#{i_tr}</span>"
                                      when 'written_off'
                                        "<span class='label label-default'>#{i_tr}</span>"
                                      end

          item['supplies'].each { |supply| supply['date'] = supply['date'].strftime('%d-%m-%Y') }
        end
      end

      def init_filters
        data[:filters] = {}

        data[:filters][:item_types] = if need_init_filters?
                                        Item.show_only_presence.pluck(:item_type).uniq
                                      else
                                        Item.pluck(:item_type).uniq
                                      end
        data[:filters][:statuses] = Item.statuses.map { |key, _val| [key, Item.translate_enum(:status, key)] }.to_h
        data[:filters][:buildings] = IssReferenceBuilding
                                       .select('iss_reference_sites.name as site_name, iss_reference_buildings.*')
                                       .left_outer_joins(:iss_reference_site)
      end

      def load_orders
        out_orders = Orders::Index.new({ start: nil, length: nil }, operation: :out, status: :processing)
        raise 'Не удалось загрузить список расходных ордеров' unless out_orders.run

        write_off_orders = Orders::Index.new({ start: nil, length: nil }, operation: :write_off, status: :processing)
        raise 'Не удалось загрузить список ордеров на списание' unless write_off_orders.run

        data[:orders] = out_orders.data[:data] + write_off_orders.data[:data]
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
