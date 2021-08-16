module Invent
  module Items
    class ToWriteOff < Invent::ApplicationService
      def initialize(current_user, item_id, location, comment = nil)
        @current_user = current_user
        @item_id = item_id
        @location = location
        @comment = comment

        super
      end

      def run
        find_item
        send_to_stock
        send_to_write_off

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
        @order = Warehouse::Orders::CreateByInvItem.new(current_user, @item, :in, @comment)

        if @order.run
          data[:barcode] = @item.barcode_item.id
          location_for_w_item

          return 
        else
          @error = @order.error
          raise 'Сервис CreateByInvItem для создания приходного ордера завершился с ошибкой'
        end
      end

      def location_for_w_item
        find_item
        assign_location(@item.warehouse_item.as_json)
      end

      def assign_location(warehouse_item)
        warehouse_item['location_attributes'] = @location.as_json

        # Для обновления расположения, если location_id существует
        # Также добавлено условие, для того, чтобы не возникало ошибки "Запись не найдена",
        # так как у некоторых warehouse_item.location_id = 0, а не nil
        warehouse_item['location_attributes']['id'] = warehouse_item['location_id'] && !warehouse_item['location_id'].zero? ? warehouse_item['location_id'] : nil

        @warehouse_item = Warehouse::Items::Update.new(@current_user, warehouse_item['id'], warehouse_item)
        @error = @warehouse_item.error unless @warehouse_item.run
      end

      def send_to_write_off
        @order = Warehouse::Orders::CreateByInvItem.new(current_user, @item, :write_off, @comment)

        if @order.run
          if Invent::Type::NAME_FOR_UNREGISTRATION_ITEM.include?(@item.type.name)
            UnregistrationWorker.perform_async(@item.invent_num, current_user.access_token)
          end

          return true
        else
          @error = @order.error
          raise 'Сервис CreateByInvItem для создания ордера на списание завершился с ошибкой'
        end
      end
    end
  end
end
