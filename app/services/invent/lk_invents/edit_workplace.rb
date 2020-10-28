module Invent
  module LkInvents
    # Получить данные о выбранном рабочем месте.
    class EditWorkplace < BaseService
      attr_reader :workplace

      # current_user - текущий пользователь
      # workplace_id - workplace_id рабочего места
      def initialize(current_user, workplace_id)
        @current_user = current_user
        @workplace_id = workplace_id
      end

      def run
        load_workplace

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      # Получить данные из БД.
      def load_workplace
        @workplace = Workplace
                       .includes(:workplace_count, :iss_reference_room, items: [:barcodes, { property_values: :property }])
                       .find(@workplace_id)
        authorize workplace, :edit?

        transform_to_json
        prepare_to_render
      end

      # Преобразовать данные в json формат и включить в него все подгруженные таблицы.
      def transform_to_json
        @data = workplace.as_json(
          include: [
            :workplace_count,
            :iss_reference_room,
            items: {
              include: [
                :warehouse_orders,
                :barcodes,
                property_values: {
                  include: :property
                }
              ]
            }
          ]
        )
      end

      # Подготовка параметров для отправки пользователю.
      def prepare_to_render
        data['division'] = data['workplace_count']['division']
        data['location_room'] = data['iss_reference_room']
        data['items_attributes'] = data['items']

        data.delete('items')
        data.delete('iss_reference_room')
        data.delete('location_room_id')
        data.delete('workplace_count')

        data['items_attributes'].each do |item|
          prepare_to_edit_item(item)
        end
      end
    end
  end
end
