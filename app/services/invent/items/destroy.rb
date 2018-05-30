module Invent
  module Items
    class Destroy < Invent::ApplicationService
      def initialize(current_user, item_id)
        @current_user = current_user
        @id = item_id

        super
      end

      def run
        find_item
        destroy_item
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        @item = Item.find(@id)
        authorize @item, :destroy?
      end

      def destroy_item
        return if @item.destroy

        error[:full_message] = @item.errors.full_messages.join('. ')
        raise 'Модель не удалена'
      end
    end
  end
end
