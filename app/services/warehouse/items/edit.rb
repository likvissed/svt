module Warehouse
  module Items
    class Edit < Warehouse::ApplicationService
      def initialize(current_user, item_id)
        @current_user = current_user
        @item_id = item_id

        super
      end

      def run
        load_item
        load_properties
        new_property_values if data[:item]['property_values'].blank?
        prepare_to_edit_item(data[:item])

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_item
        data[:item] = Item.includes(:inv_type, :property_values, :location).find(@item_id)

        authorize data[:item], :edit?

        data[:item] = data[:item]
                        .as_json(
                          include: [
                            :inv_type,
                            :location,
                            property_values: {
                              include: :property
                            }
                          ]
                        )
      end

      def load_properties
        data[:prop_data] = {}
        data[:prop_data][:file_depending] = Invent::Property::FILE_DEPENDING
        data[:prop_data][:type_with_files] = Invent::Type::TYPE_WITH_FILES

        properties = Invent::LkInvents::InitProperties.new(current_user)

        raise 'Ошибка сервиса Invent::LkInvents::InitProperties' unless properties.load_types && properties.prepare_eq_types_to_render

        data[:prop_data][:eq_types] = properties.data[:eq_types].find do |type|
          next unless data[:item]['inv_type'] && type['name'] == data[:item]['inv_type']['name']

          type['properties'] = type['properties'].select do |prop|
            data[:prop_data][:file_depending].include?(prop['name'])
          end
        end
      end

      def new_property_values
        property_ids = Invent::Property.order(:property_order).where(name: data[:prop_data][:file_depending]).pluck(:property_id)

        data[:item]['property_values'] = property_ids.map do |id|
          PropertyValue.new(
            property_id: id,
            warehouse_item_id: data[:item]['id'],
            value: ''
          ).as_json
        end
      end
    end
  end
end
