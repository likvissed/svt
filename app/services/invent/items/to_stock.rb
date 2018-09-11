module Invent
  module Items
    class ToStock < Invent::ApplicationService
      def initialize(current_user, item_id)
        @current_user = current_user
        @item_id = item_id
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
        @order = Warehouse::Orders::CreateByInvItem.new(current_user, @item)

        return true if @order.run

        raise 'Сервис CreateByInvItem завершился с ошибкой'
      end
    end
  end
end
