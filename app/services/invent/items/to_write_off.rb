module Invent
  module Items
    class ToWriteOff < Invent::ApplicationService
      def initialize(current_user, item_id)
        @current_user = current_user
        @item_id = item_id

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
        @order = Warehouse::Orders::CreateByInvItem.new(current_user, @item, :in)

        return true if @order.run

        @error = @order.error
        raise 'Сервис CreateByInvItem для создания приходного ордера завершился с ошибкой'
      end

      def send_to_write_off
        @order = Warehouse::Orders::CreateByInvItem.new(current_user, @item, :write_off)

        return true if @order.run

        @error = @order.error
        raise 'Сервис CreateByInvItem для создания ордера на списание завершился с ошибкой'
      end
    end
  end
end
