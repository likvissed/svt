module Invent
  module Items
    class ToStock < Invent::ApplicationService
      def initialize(current_user, item_id, location)
        @current_user = current_user
        @item_id = item_id
        @location = location

        super
      end

      def run
        find_item
        send_to_stock

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        @item = Invent::Item.find(@item_id)
        authorize @item, :to_stock?
      end

      def send_to_stock
        @order = Warehouse::Orders::CreateByInvItem.new(current_user, @item, :in)

        if @order.run
          assign_location
          UnregistrationWorker.perform_async(@item.invent_num, current_user.access_token)

          return
        else
          @error = @order.error
          raise 'Сервис CreateByInvItem завершился с ошибкой'
        end
      end

      def assign_location
        find_item
        w_item = @item.warehouse_item.as_json

        w_item['location_attributes'] = @location.as_json
        # Для обновления расположения, если location_id существует
        w_item['location_attributes']['id'] = w_item['location_id']

        @warehouse_item = Warehouse::Items::Update.new(@current_user, w_item['id'], w_item)

        return if @warehouse_item.run

        @error = @warehouse_item.error
        raise 'Сервис Warehouse::Items::Update завершился с ошибкой'
      end
    end
  end
end
