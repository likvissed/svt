module Invent
  module Items
    # Загрузить список техники, которая находится в работе в текущий момент.
    class Index < Invent::ApplicationService
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
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def load_items
        data[:recordsTotal] = Item.count
        @items = Item.all
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

        return unless @filters['properties']&.any?
        @filters['properties'].each do |prop|
          next if prop['property_id'].to_i.zero? || prop['property_value'].blank?

          @items = if prop['exact']
                     @items.where('invent_item.item_id IN (SELECT item_id FROM invent_property_value AS val LEFT JOIN invent_property_list AS list USING(property_list_id) WHERE val.property_id = :prop_id AND (val.value = :val OR list.short_description = :val))', prop_id: prop['property_id'], val: prop['property_value'])
                   else
                     @items.where('invent_item.item_id IN (SELECT item_id FROM invent_property_value AS val LEFT JOIN invent_property_list AS list USING(property_list_id) WHERE val.property_id = :prop_id AND (val.value LIKE :val OR list.short_description LIKE :val))', prop_id: prop['property_id'], val: "%#{prop['property_value']}%")
                   end
        end
      end

      def limit_records
        data[:recordsFiltered] = @items.count
        @items = @items
                   .includes(
                     :type,
                     :model,
                     { property_values: %i[property property_list] },
                     workplace: :user_iss
                   ).order(item_id: :desc).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @items.as_json(
          include: [
            :type,
            :model,
            { property_values: { include: %i[property property_list] } },
            { workplace: { include: :user_iss } }
          ]
        ).each do |item|
          item['model'] = item['model'].nil? ? item['item_model'] : item['model']['item_model']
          item['description'] = item['property_values'].map { |prop_val| property_value_info(prop_val) }.join('; ')
        end
      end

      def load_filters
        data[:filters] = {}
        data[:filters][:types] = Type.where('name != "unknown"')
        data[:filters][:properties] = Property.group(:name)
      end
    end
  end
end
