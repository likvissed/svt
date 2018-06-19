module Warehouse
  module Supplies
    class BaseService < Warehouse::ApplicationService
      protected

      def save_supply
        return true if @supply.save

        error[:object] = @supply.errors
        error[:full_message] = @supply.errors.full_messages.join('. ')

        Rails.logger.info error
        raise 'Поставка не сохранена'
      end

      def process_supply_errors
        supply_errors = @supply.errors.full_messages
        operation_errors = @supply.operations.map { |op| op.errors.full_messages }
        item_errors = @supply.operations.map { |op| op.item.errors.full_messages }
        @error[:full_message] = [supply_errors, operation_errors, item_errors].flatten.join('. ')
      end
    end
  end
end
