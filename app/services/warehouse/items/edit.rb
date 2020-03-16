module Warehouse
  module Items
    class Edit < Warehouse::ApplicationService
      def initialize(item_id)
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
        data[:item]['location'] ||= Location.new.as_json
      end

      def load_properties
        data[:prop_data] = {}
        data[:prop_data][:file_depending] = Invent::Property::FILE_DEPENDING
        data[:prop_data][:type_with_files] = Invent::Type::TYPE_WITH_FILES

        properties = Invent::LkInvents::InitProperties.new(current_user)

        data[:prop_data][:iss_locations] = properties.load_locations

        raise 'Ошибка сервиса Invent::LkInvents::InitProperties' unless properties.load_types && properties.prepare_eq_types_to_render

        data[:prop_data][:eq_types] = properties.data[:eq_types].find do |type|
          next unless data[:item]['inv_type'] && type['name'] == data[:item]['inv_type']['name']

          type['properties'] = type['properties'].select do |prop|
            data[:prop_data][:file_depending].include?(prop['name'])
          end
        end
      end

      def new_property_values
        data[:item]['property_values'] = data[:prop_data][:file_depending].map do |value|
          PropertyValue.new(
            property_id: Invent::Property.find_by(name: value).property_id,
            warehouse_item_id: data[:item]['id'],
            value: ''
          ).as_json
        end
      end
    end
  end
end
