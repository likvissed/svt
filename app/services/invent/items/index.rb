module Invent
  module Items
    # Класс загружает список техники, которая находится в работе в текущий момент.
    class Index < ApplicationService
      def initialize(params)
        @data = {}
        @start = params[:start]
        @length = params[:length]
      end

      def run
        load_items

        true
      rescue StandardError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace.inspect

        false
      end

      private

      def load_items
        data[:totalRecords] = InvItem.count
        data[:data] = InvItem
                        .includes(
                          :inv_type,
                          :inv_model,
                          { inv_property_values: %i[inv_property inv_property_list] },
                          workplace: :user_iss
                        )
                        .limit(@length).offset(@start)
                        .as_json(
                          include:
                            [
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
    end
  end
end
