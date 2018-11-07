module Invent
  module Models
    class Destroy < BaseService
      def initialize(model_id)
        @id = model_id

        super
      end

      def run
        find_model
        destroy_model
        broadcast_models

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_model
        @model = Model.find(@id)
      end

      def destroy_model
        return if @model.destroy

        error[:full_message] = @model.errors.full_messages.join('. ')
        raise 'Модель не удалена'
      end
    end
  end
end
