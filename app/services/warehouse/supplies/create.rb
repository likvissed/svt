module Warehouse
  module Supplies
    # Создать поставку
    class Create < BaseService
      def initialize(current_user, supply_params)
        @current_user = current_user
        @supply_params = supply_params

        super
      end

      def run
        init_items
        init_supply
        save_supply

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
        @supply_params[:operations_attributes] ||= []
        @supply_params[:operations_attributes].each do |op|
          op[:item] = find_or_generate_item(op)
          op[:item].status = :non_used
        end
      end

      def init_supply
        @supply = Supply.new(@supply_params)
        authorize @supply, :create?

        @supply.operations.each do |op|
          op.item_type = op.item.item_type
          op.item_model = op.item.item_model
          op.calculate_item_count
          op.calculate_item_invent_num_end
        end
      end
    end
  end
end
