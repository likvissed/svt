module Invent
  module Models
    class Update < BaseService
      def initialize(model_id, model_params)
        @model_id = model_id
        @model_params = model_params

        super
      end

      def run
        find_model
        update_model
        broadcast_models

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_model
        @model = Model.find(@model_id)
      end

      def update_model
        @model.assign_attributes(@model_params)
        @model.fill_item_model

        return true if @model.save

        error[:object] = @model.errors
        error[:full_message] = @model.errors.full_messages.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
