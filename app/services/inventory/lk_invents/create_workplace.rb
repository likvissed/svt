module Inventory
  module LkInvents
    # Создать рабочее место. Здесь устанавливаются все необходимые параметры (id комнаты, файл), выполняется логирование
    # полученных данных и создается рабочее место.
    class CreateWorkplace < BaseService
      include ActiveModel::Validations

      attr_reader :data, :workplace_params, :workplace

      # strong_params - параметры, пройденные фильтрацию 'strong_params'
      # file - объект файл
      def initialize(strong_params, file = nil)
        @workplace_params = strong_params.with_indifferent_access
        @file = file
      end

      def run
        create_or_get_room
        if @file.kind_of?(ActionDispatch::Http::UploadedFile) || @file.kind_of?(Rack::Test::UploadedFile)
          set_file_into_params
        end
        @workplace = Workplace.new(@workplace_params)
        log_data
        save_workplace
      rescue RuntimeError
        false
      end

      private

      # Логирование полученных данных.
      def log_data
        Rails.logger.info "Workplace: #{@workplace.inspect}".red
        @workplace.inv_items.each_with_index do |item, item_index|
          Rails.logger.info "Item [#{item_index}]: #{item.inspect}".green

          item.inv_property_values.each_with_index do |val, prop_index|
            Rails.logger.info "Prop_value [#{prop_index}]: #{val.inspect}".cyan
          end
        end
      end

      # Создать рабочее место.
      def save_workplace
        if @workplace.save
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                        .includes(inv_items: [:inv_type, { inv_property_values: :inv_property }])
                        .find(@workplace.workplace_id)

          prepare_workplace
        else
          Rails.logger.info @workplace.errors.full_messages.inspect.blue

          errors.add(:base, @workplace.errors.full_messages.join(', '))
          raise 'abort'
        end
      end
    end
  end
end
