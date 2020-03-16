module Warehouse
  module Items
    class Update < Warehouse::ApplicationService
      def initialize(current_user, item_id, item_params)
        @current_user = current_user
        @item_id = item_id
        @item_params = item_params

        super
      end

      def run
        find_item
        create_or_get_room if @item_params['location_attributes']['room_id'] == -1
        update_item_params

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        @item = Item.find(@item_id)
        authorize @item, :update?
      end

      # Создать комнату (если она не существует). Создает объект @room.
      def create_or_get_room
        room = IssReferenceRoom.find_by(name: @item_params['location_attributes']['name'], building_id: @item_params['location_attributes']['building_id'])

        category_id = if room.present?
                        room.security_category_id
                      else
                        RoomSecurityCategory.find_by(category: 'Отсутствует').id
                      end

        @room = Invent::Room.new(@item_params['location_attributes']['name'], @item_params['location_attributes']['building_id'], category_id)

        @item_params['location_attributes']['room_id'] = @room.data.room_id if @room.run
      end

      def update_item_params
        @item_params['location_attributes'].delete :name
        return if @item.update(@item_params)

        error[:full_message] = @item.errors.full_messages.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
