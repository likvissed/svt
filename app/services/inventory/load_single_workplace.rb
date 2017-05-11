module Inventory
  class LoadSingleWorkplace
    attr_reader :workplace

    def initialize(id)
      @workplace_id = id
      load
    end

    def transform
      transform_to_json
      prepare_to_render
    end

    # Проверка статуса рабочего места. true, если статус - "Подтвержден".
    def status_confirmed?
      @workplace.status == 'confirmed'
    end

    private

    # Получить данные из БД
    def load
      @workplace = Workplace
                     .includes(:iss_reference_room)
                     .find(@workplace_id)
    end

    # Преобразовать данные в json формат и включить в него все подгруженные таблицы.
    def transform_to_json
      @workplace = @workplace.as_json(
        include: {
          iss_reference_room: {},
          inv_items: {
            include: :inv_property_values
          }
        }
      )
    end

    # Подготовка параметров для отправки клиенту.
    def prepare_to_render
      @workplace['location_room_name'] = @workplace['iss_reference_room']['name']
      @workplace['inv_items_attributes'] = @workplace['inv_items']

      @workplace.delete('inv_items')
      @workplace.delete('iss_reference_room')
      @workplace.delete('location_room_id')

      @workplace['inv_items_attributes'].each do |item|
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
