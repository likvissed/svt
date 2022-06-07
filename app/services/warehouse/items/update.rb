module Warehouse
  module Items
    class Update < Warehouse::ApplicationService
      def initialize(current_user, item_id, item_params)
        @current_user = current_user
        @item_id = item_id
        @item_params = item_params

        super
      end

      def run
        find_item
        assign_binders if @item.inv_item.present? && @item_params['binders_attributes'].present?
        update_item_params
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_item
        @item = Item.find(@item_id)
        authorize @item, :update?
      end

      def assign_binders
        # Привязка к invent_item
        @item_params['binders_attributes'].each { |binder| binder['invent_item_id'] = @item.inv_item.item_id }
      end

      def update_item_params
        if @item.update(@item_params)
          data[:item] = @item
          # Добавляется расположение, для ситуаций, когда обновляется расположение в приходном ордере
          data[:json_item] = @item.as_json(include: [:location])

        else
          error[:full_message] = @item.errors.full_messages.join('. ')

          raise 'Данные не обновлены'
        end
      end
    end
  end
end
