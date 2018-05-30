module Invent
  module Workplaces
    class Destroy < BaseService
      def initialize(current_user, workplace_id)
        @current_user = current_user
        @workplace_id = workplace_id

        super
      end

      def run
        find_workplace
        destroy_workplace
        broadcast_workplaces

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_workplace
        @workplace = Workplace.find(@workplace_id)
        authorize @workplace, :destroy?
      end

      def destroy_workplace
        return if @workplace.destroy

        error[:full_message] = @workplace.errors.full_messages.join('. ')
        raise 'РМ не удалено'
      end
    end
  end
end
