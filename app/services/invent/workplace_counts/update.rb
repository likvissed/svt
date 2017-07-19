module Invent
  module WorkplaceCounts
    # Класс редактирует данные об отделе.
    class Update < ApplicationService
      attr_reader :error

      # workplace_count_id - id отдела
      # strong_params - данные, прошедшие фильтрацию.
      def initialize(workplace_count_id, strong_params)
        @error = {}
        @workplace_count_id = workplace_count_id
        @wpc_params = strong_params
      end

      def run
        @data = WorkplaceCount.includes(:users).find(@workplace_count_id)
        update_workplace
      rescue ActiveRecord::RecordInvalid, RuntimeError
        error[:object] = data.errors
        error[:full_message] = data.errors.full_messages.join('. ') + data.wp_resp_errors.join('. ')

        false
      end

      private

      # Сохранить отдел
      def update_workplace
        return true if data.update_attributes(@wpc_params)

        raise 'abort'
      end
    end
  end
end
