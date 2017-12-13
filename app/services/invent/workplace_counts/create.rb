module Invent
  module WorkplaceCounts
    # Класс создает новый отдел, для заполнения данными о РМ.
    class Create < Invent::ApplicationService
      attr_reader :error

      # strong_params - данные, прошедшие фильтрацию.
      def initialize(strong_params)
        @error = {}
        @wpc_params = strong_params
      end

      def run
        @data = WorkplaceCount.new(@wpc_params)
        save_workplace

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      # Сохранить отдел
      def save_workplace
        return true if data.save

        error[:object] = data.errors
        error[:full_message] = data.errors.full_messages.join('. ')

        raise 'Данные не сохранены'
      end
    end
  end
end
