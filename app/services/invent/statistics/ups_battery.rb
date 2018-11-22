module Invent
  module Statistics
    class UpsBattery < Invent::ApplicationService
      def initialize
        super
      end

      def run
        load_critical_ups
        process_data

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_critical_ups
        type = Invent::Type.find_by(name: :ups)
        @property_battery_type = type.properties.find_by(name: :battery_type)
        @property_battery_count = type.properties.find_by(name: :battery_count)
        @property_battery_module = type.properties.find_by(name: :battery_module)
        @data = @property_battery_type.property_lists.map do |prop_list|
          {
            id: prop_list.property_list_id,
            value: prop_list.value,
            description: prop_list.short_description,
            total_count: 0,
            to_replace_count: 0
          }
        end

        @ups = Invent::Item.where(type: type, priority: :high).includes(:type)
      end

      def process_data
        @ups.find_each do |ups|
          arr_el = data.find { |i| i[:id] == ups.property_values.find_by(property: @property_battery_type).property_list_id }

          battery_count = ups.property_values.find_by(property: @property_battery_count)&.property_list&.value.to_i
          battery_module = ups.property_values.find_by(property: @property_battery_module)&.value.to_i

          count = battery_count + battery_module
          arr_el[:total_count] += count
          next unless ups.need_battery_replacement?

          arr_el[:to_replace_count] += count
        end
      end
    end
  end
end
