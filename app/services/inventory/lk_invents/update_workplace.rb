module Inventory
  module LkInvents
    # Обновить данные о рабочем месте.
    class UpdateWorkplace < BaseService
      attr_reader :workplace_params, :workplace

      # current_user - текущий пользователь
      # workplace_id - workplace_id изменяемого рабочего места
      # strong_params - параметры, пройденные фильтрацию 'strong_params'
      # file - объект файл
      def initialize(current_user, workplace_id, strong_params, file = nil)
        @current_user = current_user
        @workplace_id = workplace_id
        @workplace_params = strong_params.deep_symbolize_keys
        @file = file
      end

      def run
        @workplace = Workplace.find(@workplace_id)
        authorize @workplace, :update?

        prepare_params
        update_workplace
        broadcast_workplaces
      rescue RuntimeError
        false
      end

      private

      def update_workplace
        if workplace.update(workplace_params)
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                         .includes(
                           :iss_reference_site,
                           :iss_reference_building,
                           :iss_reference_room,
                           inv_items: { inv_property_values: :inv_property }
                         )
                         .find(workplace.workplace_id)

          prepare_workplace
        else
          Rails.logger.error workplace.errors.full_messages.inspect.red

          errors.add(:base, workplace.errors.full_messages.join('. '))
          raise 'abort'
        end
      end
    end
  end
end
