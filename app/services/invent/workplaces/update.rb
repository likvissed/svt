module Invent
  module Workplaces
    # Обновить данные о рабочем месте.
    class Update < BaseService
      # current_user - текущий пользователь
      # workplace_id - workplace_id изменяемого рабочего места
      # workplace_params - параметры, пройденные фильтрацию 'strong_params'
      def initialize(current_user, workplace_id, workplace_params, workplace_attachments)
        @current_user = current_user
        @workplace_id = workplace_id
        @workplace_params = workplace_params
        @workplace_attachments = workplace_attachments

        super
      end

      def run
        @workplace = Workplace.find(@workplace_id)
        authorize @workplace, :update?

        if @workplace_params['items_attributes'].present?
          assing_barcode
          delete_property_value
        end

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
        if @workplace.update(@workplace_params)
          create_attachments if @workplace_attachments.present?

          Invent::ChangeOwnerWpWorker.perform_async(@workplace.workplace_id, @workplace.data_change_id_tn, current_user.access_token) if @workplace.data_change_id_tn.present?

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
          workplace_errors = @workplace.errors.full_messages
          operation_errors = @workplace.items.map { |item| item.errors.full_messages }
          error[:full_message] = [workplace_errors, operation_errors].flatten.uniq.join('. ')

          raise 'Данные не обновлены'
        end
      end
    end
  end
end
