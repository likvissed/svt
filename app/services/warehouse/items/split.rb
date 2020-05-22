module Warehouse
  module Items
    class Split < Warehouse::ApplicationService
      def initialize(current_user, item_id, items_attributes)
        @current_user = current_user
        @item_id = item_id
        @items_attributes = items_attributes

        super
      end

      def run
        present_count_for_invent_num

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def present_count_for_invent_num
        value_count_invent = @items_attributes.any? { |item| item['count_for_invent_num'].blank? }

        return false if value_count_invent

        find_item
        fill_with_new_data
      end

      def find_item
        @item = Item.find(@item_id)
        authorize @item, :update?
      end

      def fill_with_new_data
        current_invent_num = @item.invent_num_start

        @items_attributes.each_with_index do |item, index|
          current_item = if index.zero?
                           @item.as_json
                         else
                           old_item = @item.as_json
                           old_item['id'] = ''
                           old_item['count_reserved'] = 0

                           item['property_values_attributes'].each { |prop_val| prop_val['id'] = '' } if item['property_values_attributes'].present?

                           Item.create(old_item).as_json
                         end
          current_item['count'] = item['count_for_invent_num']

          unless current_invent_num.nil?
            current_item['invent_num_start'] = current_invent_num
            current_item['invent_num_end'] = current_invent_num + item['count_for_invent_num'].to_i - 1

            current_invent_num = current_item['invent_num_end'] + 1
          end

          current_item['location_attributes'] = item['location'].as_json
          current_item['property_values_attributes'] = item['property_values_attributes'].as_json

          update_w_item(current_item)
        end
      end

      def update_w_item(item)
        # Присвоить расположение для техники
        Items::Update.new(@current_user, item['id'], item).run

        create_or_update_operation(item['id'])
      end

      def create_or_update_operation(item_id)
        item = Item.find(item_id)

        supply_id = @item.supplies.first.id if @item.supplies.present?

        # Флаг, по которому отпределяем, была ли обновлена операция
        flag = true

        operation = item.operations.build(
          item_id: item['id'],
          shift: item['count'],
          status: :processing,
          operationable_id: supply_id,
          operationable_type: 'Warehouse::Supply',
          item_type: item['item_type'],
          item_model: item['item_model'],
          date: Time.zone.now
        )
        operation.set_stockman(current_user)

        if @item.id == item_id
          op = Operation.find_by(item_id: @item.id)

          if op.present?
            operation['id'] = op.id
            op.update(operation.as_json)

            flag = false
          end
        end

        operation.save if flag
      end
    end
  end
end
