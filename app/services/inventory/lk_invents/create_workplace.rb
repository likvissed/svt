module Inventory
  module LkInvents
    # Создать рабочее место. Здесь устанавливаются все необходимые параметры (id комнаты, файл), выполняется логирование
    # полученных данных и создается рабочее место.
    class CreateWorkplace < BaseService
      attr_reader :workplace_params, :workplace

      # current_user - текущий пользователь
      # strong_params - параметры, пройденные фильтрацию 'strong_params'
      # file - объект файл
      def initialize(current_user, strong_params, file = nil)
        @current_user = current_user
        @workplace_params = strong_params
        @file = file
      end

      def run
        prepare_params

        @workplace = Workplace.new(workplace_params)
        log_data

        authorize @workplace, :create?
        save_workplace
      rescue RuntimeError
        false
      end

      private

      # Логирование полученных данных.
      def log_data
        Rails.logger.info "Workplace: #{workplace.inspect}".red
        workplace.inv_items.each_with_index do |item, item_index|
          Rails.logger.info "Item [#{item_index}]: #{item.inspect}".green

          item.inv_property_values.each_with_index do |val, prop_index|
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
                        .includes(inv_items: [:inv_type, { inv_property_values: :inv_property }])
                        .find(workplace.workplace_id)

          prepare_workplace
        else
          Rails.logger.error workplace.errors.full_messages.inspect.red

          errors.add(:base, workplace.errors.full_messages.join(', '))
          raise 'abort'
        end
      end
    end
  end
end
