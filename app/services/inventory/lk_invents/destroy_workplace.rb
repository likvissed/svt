module Inventory
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
        @data = Workplace.find(@workplace_id)
        authorize @data, :destroy?

        destroy_workplace
        broadcast_workplaces
      rescue RuntimeError
        false
      end

      private

      def destroy_workplace
        return true if data.destroy_from_***REMOVED***
        Rails.logger.error data.errors.full_messages.inspect.red

        errors.add(:base, data.errors.full_messages.join(', '))
        raise 'abort'
      end
    end
  end
end
