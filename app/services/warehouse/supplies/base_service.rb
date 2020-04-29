module Warehouse
  module Supplies
    class BaseService < Warehouse::ApplicationService
      protected

      def find_or_generate_item(op)
        op[:item] = setting_location_attributes(op[:item])

        if op[:item][:warehouse_type].to_s == 'without_invent_num'
          Item.find_by(item_type: op[:item][:item_type], item_model: op[:item][:item_model], status: :non_used) || Item.new(op[:item])
        else
          Item.new(op[:item])
        end
      end

      def setting_location_attributes(item)
        item[:location_attributes] = item[:location]
        item.delete(:location)

        if item[:location_attributes].present?
          if item[:location_attributes]['room_id'] == -1
            @room = Invent::Room.new(item[:location_attributes]['name'], item[:location_attributes]['building_id'], RoomSecurityCategory.missing_category.id)

            item[:location_attributes]['room_id'] = @room.data.room_id if @room.run
          end
          item[:location_attributes].delete :name
        end
        item
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
