module Invent
  module Workplaces
    # Обновить данные о рабочем месте.
    class Update < BaseService
      # current_user - текущий пользователь
      # workplace_id - workplace_id изменяемого рабочего места
      # workplace_params - параметры, пройденные фильтрацию 'strong_params'
      def initialize(current_user, workplace_id, workplace_params)
        @current_user = current_user
        @workplace_id = workplace_id
        @workplace_params = workplace_params

        super
      end

      def run
        @workplace = Workplace.find(@workplace_id)
        authorize @workplace, :update?

        create_or_get_room
        fill_swap_arr

        Workplace.transaction do
          update_workplace
          swap_items if @swap.any?
        end

        broadcast_items
        broadcast_workplaces
        broadcast_workplaces_list
        broadcast_archive_orders if @swap.any?

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def update_workplace
        if @workplace.update_attributes(@workplace_params)
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                         .includes(
                           :iss_reference_site,
                           :iss_reference_building,
                           :iss_reference_room,
                           items: %i[type property_values]
                         )
                         .find(@workplace.workplace_id)

          prepare_workplace
        else
          error[:full_message] = @workplace.errors.full_messages.join('. ')
          raise 'Данные не обновлены'
        end
      end
    end
  end
end
