module Warehouse
  module Supplies
    class BaseService < Warehouse::ApplicationService
      protected

      def find_supply
        @supply = Supply.includes(operations: :item).find(@supply_id)
      end

      def save_supply
        return true if @supply.save

        @error[:object] = @supply.errors
        @error[:full_message] = @supply.errors.full_messages.join('. ')
        raise 'Поставка не сохранена'
      end
    end
  end
end