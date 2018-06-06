module Invent
  module Workplaces
    class HardDestroy < BaseService
      def initialize(current_user, workplace_id)
        @current_user = current_user
        @workplace_id = workplace_id

        super
      end

      def run
        find_workplace

        Item.transaction do
          Warehouse::InvItemToOperation.transaction(requires_new: true) do
            destroy_items
            destroy_workplace
          end
        end

        broadcast_items
        broadcast_workplaces
        broadcast_workplaces_list

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_workplace
        @workplace = Workplace.find(@workplace_id)
        authorize @workplace, :hard_destroy?
      end

      def destroy_items
        @workplace.items
          .includes(:property_values, :warehouse_inv_item_to_operations, :warehouse_item)
          .each { |item| raise "Ошибка удаления Invent::Item #{item}" unless item.destroy }
      end

      def destroy_workplace
        return if @workplace.destroy

        error[:full_message] = @workplace.errors.full_messages.join('. ')
        raise 'РМ не удалено'
      end
    end
  end
end
