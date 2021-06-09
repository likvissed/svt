module Invent
  module Workplaces
    # Создание рабочего места
    class Create < BaseService
      # current_user - текущий пользователь
      # workplace_params - параметры, пройденные фильтрацию 'strong_params'
      def initialize(current_user, workplace_params, workplace_attachments)
        @current_user = current_user
        @workplace_params = workplace_params
        @workplace_attachments = workplace_attachments

        super
      end

      def run
        fill_swap_arr
        if @workplace_params['items_attributes'].present?
          assing_barcode
          delete_property_value
        end

        @workplace = Workplace.new(@workplace_params)
        log_data
        authorize @workplace, :create?

        Workplace.transaction do
          save_workplace
          swap_items if @swap.any?
        end

        broadcast_workplaces
        broadcast_workplaces_list
        broadcast_items
        broadcast_archive_orders if @swap.any?

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      # Логирование полученных данных.
      def log_data
        Rails.logger.info "Workplace: #{@workplace.inspect}".red
        @workplace.items.each_with_index do |item, item_index|
          Rails.logger.info "Item [#{item_index}]: #{item.inspect}".green

          item.property_values.each_with_index do |val, prop_index|
            Rails.logger.info "Prop_value [#{prop_index}]: #{val.inspect}".cyan
          end
        end
      end

      # Создать рабочее место.
      def save_workplace
        if @workplace.save
          create_attachments if @workplace_attachments.present?
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                         .includes(items: [:type, { property_values: :property }])
                         .find(@workplace.workplace_id)

          prepare_workplace
        else
          error[:full_message] = @workplace.errors.full_messages.join('. ')
          raise 'Рабочее место не сохранено'
        end
      end
    end
  end
end
