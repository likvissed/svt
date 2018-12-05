module Invent
  module Items
    # Загрузить список техники, которая находится в работе в текущий момент.
    class Index < Invent::ApplicationService
      def initialize(params)
        @params = params

        super
      end

      def run
        load_items
        limit_records
        prepare_to_render
        load_filters if need_init_filters?

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
        run_filters if params[:filters]
      end

      def run_filters
        @items = @items.filter(filtering_params)
      end

      def filtering_params
        JSON.parse(params[:filters]).slice('item_id', 'type_id', 'invent_num', 'item_model', 'responsible', 'status', 'properties', 'location_building_id', 'location_room_id', 'priority')
      end

      def limit_records
        data[:recordsFiltered] = @items.count
        @items = @items
                   .includes(
                     :type,
                     :model,
                     { property_values: %i[property property_list] },
                     workplace: :user_iss
                   ).order(item_id: :desc).limit(params[:length]).offset(params[:start])
      end

      def prepare_to_render
        data[:data] = @items.as_json(
          include: [
            :type,
            :model,
            { property_values: { include: %i[property property_list] } },
            { workplace: { include: :user_iss } }
          ],
          methods: :need_battery_replacement?
        ).each do |item|
          item['model'] = item['model'].nil? ? item['item_model'] : item['model']['item_model']
          item['description'] = item['property_values'].map { |prop_val| property_value_info(prop_val) }.join('; ')
          item['translated_status'] = (str = Item.translate_enum(:status, item['status'])).is_a?(String) ? str : ''
          item['translated_priority'] = Item.translate_enum(:priority, item['priority'])
          item['label_status'] = label_status(item, item['translated_status'])
        end
      end

      def load_filters
        data[:filters] = {}
        data[:filters][:types] = Type.where('name != "unknown"')
        # data[:filters][:properties] = Property.group(:name).includes(:property_lists).as_json(include: :property_lists)
        data[:filters][:properties] = PropertyToType
                                        .select('type_id, property_id, t.short_description as type_description, p.long_description, p.property_type')
                                        .joins('
                                          JOIN invent_type AS t USING(type_id)
                                          JOIN invent_property AS p USING(property_id)
                                        ')
                                        .includes(property: :property_lists)
                                        .as_json(include: { property: { include: :property_lists } })
        data[:filters][:statuses] = item_statuses
        data[:filters][:buildings] = IssReferenceBuilding
                                       .select('iss_reference_sites.name as site_name, iss_reference_buildings.*')
                                       .left_outer_joins(:iss_reference_site)
        data[:filters][:priorities] = item_priorities
      end

      def label_status(item, text)
        label_class = case item['status']
                      when 'waiting_take'
                        'label-primary'
                      when 'waiting_bring'
                        'label-warning'
                      when 'in_stock'
                        'label-info'
                      when 'waiting_write_off'
                        'label-danger'
                      when 'write_off'
                        'label-default'
                      else
                        'label-success'
                      end

        "<span class='label #{label_class}'>#{text}</span>"
      end

      def item_statuses
        Invent::Item.statuses.map { |key, _val| [key, Invent::Item.translate_enum(:status, key)] }.to_h
      end
    end
  end
end
