module Invent
  module Models
    class Create < Invent::ApplicationService
      def initialize(model_params)
        @model_params = model_params

        super
      end

      def run
        create_model
        broadcast_models

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def create_model
        model = Model.new(@model_params)
        model.fill_item_model

        return if model.save

        error[:object] = model.errors
        error[:full_message] = model.errors.full_messages.join('. ')
        raise 'Модель не сохранена'
      end
    end
  end
end
