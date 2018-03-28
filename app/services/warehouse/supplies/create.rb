module Warehouse
  module Supplies
    # Создать поставку
    class Create < BaseService
      def initialize(current_user, supply_params)
        @error = {}
        @current_user = current_user
        @supply_params = supply_params
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
          op[:item] = Item.find_by(item_type: op[:item][:item_type], item_model: op[:item][:item_model]) || Item.new(op[:item])
          op[:item].used = false
        end
      end

      def init_supply
        @supply = Supply.new(@supply_params)
        @supply.operations.each do |op|
          op.item_type = op.item.item_type
          op.item_model = op.item.item_model
          op.calculate_item_count
        end
      end
    end
  end
end