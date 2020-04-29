module Warehouse
  module Supplies
    class Update < BaseService
      def initialize(current_user, supply_id, supply_params)
        @current_user = current_user
        @supply_id = supply_id
        @supply_params = supply_params.to_h.with_indifferent_access

        super
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

      def find_supply
        @supply = Supply.includes(operations: :item).find(@supply_id)
        authorize @supply, :update?
      end

      def init_items
        return unless @supply_params[:operations_attributes]

        @supply_params[:operations_attributes].each do |op|
          item = op[:item]
          location = item[:location]

          op[:item] = if item[:id]
                        Item.find(item[:id])
                      else
                        find_or_generate_item(op)
                      end
          item = setting_location_attributes(item)
          op[:item].status = :non_used

          if item[:location_attributes].blank?
            item[:location_attributes] = location
            item.delete(:location_attributes) if item[:warehouse_type] == 'without_invent_num' && item[:location_attributes].nil?
          end

          if item[:warehouse_type] == 'with_invent_num' && item[:location_attributes].nil?
            @supply.location_attr = true && @supply.value_location_item_type = item[:item_type]
          else
            op[:item].assign_attributes(item)
          end
        end
      end

      def assign_supply_params
        @supply.assign_attributes(@supply_params)
        @supply.operations.each do |op|
          op.item_type = op.item.item_type
          op.item_model = op.item.item_model
          op.calculate_item_count
          op.calculate_item_invent_num_end
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

            process_supply_errors

            raise ActiveRecord::Rollback
          rescue ActiveRecord::RecordNotDestroyed
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            Rails.logger.error e.inspect.red
            Rails.logger.error e.backtrace[0..5].inspect

            process_supply_errors

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
