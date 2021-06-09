module Invent
  module LkInvents
    # Получить данные о выбранном рабочем месте.
    class EditWorkplace < BaseService
      attr_reader :workplace

      # current_user - текущий пользователь
      # workplace_id - workplace_id рабочего места
      def initialize(current_user, workplace_id)
        @current_user = current_user
        @workplace_id = workplace_id
      end

      def run
        load_workplace

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      # Получить данные из БД.
      def load_workplace
        @workplace = Workplace
                       .includes(:workplace_count, :iss_reference_room, :attachments, items: [:barcode_item, { property_values: :property }])
                       .find(@workplace_id)
        authorize workplace, :edit?

        transform_to_json
        prepare_to_render
      end

      # Преобразовать данные в json формат и включить в него все подгруженные таблицы.
      def transform_to_json
        @data = workplace.as_json(
          include: [
            :workplace_count,
            :attachments,
            items: {
              include: [
                :warehouse_orders,
                :barcode_item,
                property_values: {
                  include: :property
                }
              ]
            }
          ]
        )
      end

      # Подготовка параметров для отправки пользователю.
      def prepare_to_render
        data['division'] = data['workplace_count']['division']
        data['items_attributes'] = data['items']
        data['attachments_attributes'] = data['attachments']

        data.delete('items')
        data.delete('attachments')
        data.delete('workplace_count')
        data.delete('workplace_count')

        data['items_attributes'].each do |item|
          prepare_to_edit_item(item)
        end

        # Вывести в поле filename имя файла, если он существует
        data['attachments_attributes'].each { |att| att['filename'] = att['document'].file.nil? ? 'Файл отсутствует' : att['document'].identifier }

        data['new_attachment'] = @workplace.attachments.build
      end
    end
  end
end
