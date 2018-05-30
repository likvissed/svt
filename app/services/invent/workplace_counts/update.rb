module Invent
  module WorkplaceCounts
    # Редактирование доступа для отдела.
    class Update < Invent::ApplicationService
      # workplace_count_id - id отдела
      # strong_params - данные, прошедшие фильтрацию.
      def initialize(workplace_count_id, strong_params)
        @workplace_count_id = workplace_count_id
        @wpc_params = strong_params

        super
      end

      def run
        @data = WorkplaceCount.includes(:users).find(@workplace_count_id)
        update_workplace
        broadcast_users

        true
      rescue ActiveRecord::RecordInvalid, RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      # Сохранить отдел
      def update_workplace
        return true if data.update_attributes(@wpc_params)

        error[:object] = data.errors
        error[:full_message] = data.errors.full_messages.join('. ') + data.wp_resp_errors.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
