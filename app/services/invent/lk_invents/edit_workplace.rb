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
      rescue RuntimeError
        false
      end

      private

      # Получить данные из БД.
      def load_workplace
        @workplace = Workplace
                       .includes(:workplace_count, :iss_reference_room, inv_items: { inv_property_values: :inv_property })
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
            inv_items: {
              include: {
                inv_property_values: {
                  include: :inv_property
                }
              }
            }
          ]
        )
      end

      # Подготовка параметров для отправки пользователю.
      def prepare_to_render
        data['division'] = data['workplace_count']['division']
        data['location_room_name'] = data['iss_reference_room']['name']
        data['inv_items_attributes'] = data['inv_items']

        data.delete('inv_items')
        data.delete('iss_reference_room')
        data.delete('location_room_id')
        data.delete('workplace_count')

        data['inv_items_attributes'].each do |item|
          prepare_to_edit_item(item)
        end
        data['inv_item_ids'] = data['inv_items_attributes'].map { |item| item['id'] }
      end
    end
  end
end
