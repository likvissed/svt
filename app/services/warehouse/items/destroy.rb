module Warehouse
  module Items
    # Удалить технику со склада
    class Destroy < Warehouse::ApplicationService
      def initialize(current_user, item_id)
        @current_user = current_user
        @item_id = item_id

        super
      end

      def run
        destroy_item
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def destroy_item
        @item = Item.find(@item_id)
        authorize @item, :destroy?
        return if @item.destroy

        error[:full_message] = @item.errors.full_messages.join('. ')
        raise 'Ордер не удален'
      end
    end
  end
end
