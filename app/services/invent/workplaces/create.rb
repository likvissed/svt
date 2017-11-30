module Invent
  module Workplaces
    # Создание рабочего места
    class Create < BaseService
      attr_reader :workplace_params, :workplace

      # current_user - текущий пользователь
      # workplace_params - параметры, пройденные фильтрацию 'strong_params'
      def initialize(current_user, workplace_params)
        @current_user = current_user
        @workplace_params = workplace_params
      end

      def run
        create_or_get_room
        @workplace = Workplace.new(workplace_params)
        log_data
        authorize @workplace, :create?
        save_workplace
        broadcast_workplaces
        broadcast_workplace_list

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      # Логирование полученных данных.
      def log_data
        Rails.logger.info "Workplace: #{workplace.inspect}".red
        workplace.items.each_with_index do |item, item_index|
          Rails.logger.info "Item [#{item_index}]: #{item.inspect}".green

          item.property_values.each_with_index do |val, prop_index|
            Rails.logger.info "Prop_value [#{prop_index}]: #{val.inspect}".cyan
          end
        end
      end

      # Создать рабочее место.
      def save_workplace
        if workplace.save
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                         .includes(items: [:type, { property_values: :property }])
                         .find(workplace.workplace_id)

          prepare_workplace
        else
          Rails.logger.error(workplace.errors.full_messages.inspect.red)

          errors.add(:base, workplace.errors.full_messages.join('. '))
          raise 'Рабочее место не сохранено'
        end
      end
    end
  end
end
