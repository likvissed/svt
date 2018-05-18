module Warehouse
  module Supplies
    class Destroy < BaseService
      def initialize(current_user, supply_id)
        @current_user = current_user
        @supply_id = supply_id
      end

      def run
        find_supply
        return false unless wrap_with_transaction

        broadcast_supplies
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_supply
        @supply = Supply.includes(operations: :item).find(@supply_id)
        authorize @supply, :destroy?
      end

      def wrap_with_transaction
        Item.transaction do
          begin
            update_items
            destroy_order
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def update_items
        @supply.operations.each do |op|
          op.mark_for_destruction
          op.calculate_item_count
          op.item.save!
        end
      end

      def destroy_order
        return true if @supply.destroy

        @data = @supply.errors.full_messages.join('. ')
        raise 'Поставка не удалена'
      end
    end
  end
end
