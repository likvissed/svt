module Inventory
  module LkInvents
    # Обновить данные о рабочем месте.
    class UpdateWorkplace < BaseService
      attr_reader :workplace_params, :workplace

      # workplace_id - workplace_id изменяемого рабочего места
      # strong_params - параметры, пройденные фильтрацию 'strong_params'
      # file - объект файл
      def initialize(workplace_id, strong_params, file = nil)
        @workplace_id = workplace_id
        @workplace_params = strong_params.with_indifferent_access
        @file = file
      end

      def run
        @workplace = Workplace.find(@workplace_id)

        create_or_get_room
        if @file.kind_of?(ActionDispatch::Http::UploadedFile) || @file.kind_of?(Rack::Test::UploadedFile)
          set_file_into_params
        end
        update_workplace
      rescue RuntimeError
        false
      end

      private

      def update_workplace
        if @workplace.update(@workplace_params)
          # Чтобы избежать N+1 запрос в методе 'transform_workplace' нужно создать объект ActiveRecord (например,
          # вызвать find)
          @workplace = Workplace
                         .includes(
                           :iss_reference_site,
                           :iss_reference_building,
                           :iss_reference_room,
                           inv_items: { inv_property_values: :inv_property }
                         )
                         .find(@workplace.workplace_id)

          prepare_workplace
        else
          Rails.logger.error @workplace.errors.full_messages.inspect.red

          errors.add(:base, @workplace.errors.full_messages.join(', '))
          raise 'abort'
        end
      end
    end
  end
end
