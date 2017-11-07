module Invent
  module Items
    # Класс загружает список техники, которая находится в работе в текущий момент.
    class Index < ApplicationService
      def initialize(params)
        @data = {}
        @start = params[:start]
        @length = params[:length]
        @init_filters = params[:init_filters]
        @filters = params[:filters].class.name == 'String' ? JSON.parse(params[:filters]) : params[:filters]
      end

      def run
        load_items
        run_filters if @filters
        limit_records
        prepare_to_render
        load_filters if @init_filters == 'true'

        true
      rescue StandardError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace.inspect

        false
      end

      private

      def load_items
        @items = InvItem
      end

      def run_filters
        unless @filters['item_id'].to_i.zero?
          @items = @items.where(item_id: @filters['item_id'])
        end

        unless @filters['type_id'].to_i.zero?
          @items = @items.where(type_id: @filters['type_id'])
        end

        if @filters['invent_num'].present?
          @items = @items.where('invent_num LIKE ?', "%#{@filters['invent_num']}%")
        end

        if @filters['responsible'].present?
          @items = @items.left_outer_joins(workplace: :user_iss).where('fio LIKE ?', "%#{@filters['responsible']}%")
        end

        if @filters['properties'] && !@filters['properties'].count.zero?
          @filters['properties'].each_with_index do |prop_id, index|
            next if prop_id.to_i.zero? || @filters['prop_values'][index].empty?

            @items = @items.where('invent_item.item_id IN (SELECT item_id FROM invent_property_value AS val LEFT JOIN invent_property_list AS list USING(property_list_id) WHERE val.property_id = :prop_id AND (val.value LIKE :val OR list.short_description LIKE :val))', prop_id: prop_id, val: "%#{@filters['prop_values'][index]}%")
          end
        end
      end

      def limit_records
        data[:totalRecords] = @items.count
        @items = @items
                   .includes(
                     :inv_type,
                     :inv_model,
                     { inv_property_values: %i[inv_property inv_property_list] },
                     workplace: :user_iss
                   ).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @items.as_json(
          include: [
            :inv_type,
            :inv_model,
            { inv_property_values: { include: %i[inv_property inv_property_list] } },
            { workplace: { include: :user_iss } }
          ]
        ).each do |item|
          item['model'] = item['inv_model'].nil? ? item['item_model'] : item['inv_model']['item_model']
          item['description'] = item['inv_property_values'].map { |prop_val| property_value_info(prop_val) }.join('; ')
        end
      end

      def load_filters
        data[:filters] = {}
        data[:filters][:inv_types] = InvType.where('name != "unknown"')
        data[:filters][:inv_properties] = InvProperty.group(:name)
      end
    end
  end
end
