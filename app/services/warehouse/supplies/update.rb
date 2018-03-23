module Warehouse
  module Supplies
    class Update < BaseService
      def initialize(current_user, supply_id, supply_params)
        @error = {}
        @supply_id = supply_id
        @supply_params = supply_params
      end

      def run
        find_supply
        init_items
        assign_supply_params
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

      def init_items
        return unless @supply_params['operations_attributes']

        @supply_params['operations_attributes'].each do |op|
          item = op['item']
          op['item'] = if item['id']
                         Item.find(item['id'])
                       else
                         Item.find_by(item_type: item['item_type'], item_model: item['item_model']) || Item.new(item)
                       end

          op['item'].used = false
          op['item'].assign_attributes(item)
        end
      end

      def assign_supply_params
        @supply.assign_attributes(@supply_params)
        @supply.operations.each do |op|
          op.item_type = op.item.item_type
          op.item_model = op.item.item_model
          op.calculate_item_count
        end
      end

      def wrap_with_transaction
        Item.transaction do
          begin
            update_items
            save_supply
          rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          rescue ActiveRecord::RecordNotDestroyed
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            raise ActiveRecord::Rollback
          end
        end
      end

      def update_items
        @supply.operations.each { |op| op.item.save! if op.marked_for_destruction? }
      end
    end
  end
end
