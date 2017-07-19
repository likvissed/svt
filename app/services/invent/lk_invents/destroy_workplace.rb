module Invent
  module LkInvents
    # Удалить рабочее место.
    class DestroyWorkplace < BaseService
      # current_user - текущий пользователь
      # workplace_id - workplace_id удаляемого рабочего места
      def initialize(current_user, workplace_id)
        @current_user = current_user
        @workplace_id = workplace_id
      end

      def run
        @data = Workplace.includes(inv_items: { inv_property_values: :inv_property }).find(@workplace_id)
        authorize @data, :destroy?

        destroy_workplace
        broadcast_workplaces
        broadcast_workplace_list

        true
      rescue RuntimeError
        false
      end

      private

      def destroy_workplace
        return true if data.destroy_from_***REMOVED***
        Rails.logger.error data.errors.full_messages.inspect.red

        errors.add(:base, data.errors.full_messages.join('. '))
        raise 'abort'
      end
    end
  end
end
