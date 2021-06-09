module Warehouse
  module Items
    class Create < Warehouse::ApplicationService
      def initialize(current_user, item_params)
        @current_user = current_user
        @item_params = item_params

        super
      end

      def run
        create_item

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def create_item
        item = Item.new(@item_params)
        authorize item, :create?

        if item.save
          data[:item] = item
        else
          error[:object] = item.errors
          error[:full_message] = item.errors.full_messages.join('. ')

          raise 'Техника на складе не создана'
        end
      end
    end
  end
end
