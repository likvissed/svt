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

      def update_item_params
        return if @item.update(@item_params)

        error[:full_message] = @item.errors.full_messages.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
