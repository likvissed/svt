module Inventory
  module LkInvents
    # Получить данные о выбранном рабочем месте.
    class EditWorkplace
      include ActiveModel::Validations

      attr_reader :data, :workplace_id

      # workplace_id - workplace_id рабочего места
      def initialize(workplace_id)
        @workplace_id = workplace_id
      end

      def run
        load_workplace
      rescue RuntimeError
        false
      end

      private

      # Проверка статуса рабочего места. True, если статус = "Подтвержден". (Возможно будет перенесено в Ability)
      # def status_confirmed?
      #   @workplace.status == 'confirmed'
      # end

      # Получить данные из БД.
      def load_workplace
        @data = Workplace
                  .includes(:iss_reference_room, { inv_items: :inv_property_values })
                  .find(@workplace_id)

        transform_to_json
        prepare_to_render
      end

      # Преобразовать данные в json формат и включить в него все подгруженные таблицы.
      def transform_to_json
        @data = @data.as_json(
          include: {
            iss_reference_room: {},
            inv_items: {
              include: :inv_property_values
            }
          }
        )
      end

      # Подготовка параметров для отправки пользователю.
      def prepare_to_render
        @data['location_room_name'] = @data['iss_reference_room']['name']
        @data['inv_items_attributes'] = @data['inv_items']

        @data.delete('inv_items')
        @data.delete('iss_reference_room')
        @data.delete('location_room_id')

        @data['inv_items_attributes'].each do |item|
          item['id'] = item['item_id']
          item['inv_property_values_attributes'] = item['inv_property_values']

          item.delete('item_id')
          item.delete('inv_property_values')

          item['inv_property_values_attributes'].each do |prop_val|
            prop_val['id'] = prop_val['property_value_id']

            prop_val.delete('property_value_id')
          end
        end
      end
    end
  end
end
