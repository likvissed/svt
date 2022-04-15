module Warehouse
  module Supplies
    class BaseService < Warehouse::ApplicationService
      protected

      def find_or_generate_item(op)
        setting_location_attributes(op[:item])

        if op[:item][:warehouse_type].to_s == 'without_invent_num'
          present_w_item = Item.find_by(item_type: op[:item][:item_type], item_model: op[:item][:item_model], status: :non_used)

          if present_w_item.present?
            match_location(present_w_item, op[:item])
          else
            Item.new(op[:item])
          end
        else
          Item.new(op[:item])
        end
      end

      def setting_location_attributes(item)
        item[:location_attributes] = item[:location]
        item.delete(:location)

        item
      end

      # Проверить совпадает ли расположение для новой техники и существующей с одинаковым типом, модели и статусом
      def match_location(item, new_item)
        if item.location.present? && item.location.site_id == new_item[:location_attributes]['site_id'] &&
           item.location.building_id == new_item[:location_attributes]['building_id'] &&
           item.location.room_id == new_item[:location_attributes]['room_id']

          item
        else
          Item.new(new_item)
        end
      end

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
