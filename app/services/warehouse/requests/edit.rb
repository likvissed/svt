module Warehouse
  module Requests
    class Edit < Warehouse::ApplicationService
      def initialize(current_user, request_id)
        @current_user = current_user
        @request_id = request_id

        super
      end

      def run
        load_request
        load_workers
        load_recommendations
        transform_to_json

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        data[:request] = Request.includes(
          :request_items,
          :attachments,
          order: {
            operations: %i[
              item
              inv_items
            ]
          }
        ).find(@request_id)

        authorize data[:request], :edit?
      end

      def load_workers
        data[:workers] = Role.find_by(name: 'worker').users.as_json
      end

      def load_recommendations
        data[:list_recommendations] = [
          { 'name': 'New i3' },
          { 'name': 'New i5' },
          { 'name': 'New i7' },

          { 'name': 'Ref i3' },
          { 'name': 'Ref i5' },
          { 'name': 'Ref i7' },

          { 'name': 'Самосбор i3' },
          { 'name': 'Самосбор i5' },
          { 'name': 'Самосбор i7' },

          { 'name': '2duo-quad' },

          { 'name': 'Без монитора' },
          { 'name': 'Монитор 22”' },
          { 'name': 'Монитор 24”' },
          { 'name': 'Монитор 27”' },

          { 'name': 'Видео графическая' },
          { 'name': 'Видео офисная' },
          { 'name': 'Без видео' },

          { 'name': 'Память 4 Гб' },
          { 'name': 'Память 8 Гб' },
          { 'name': 'Память 16 Гб' },
          { 'name': 'Память 32 Гб' },
          { 'name': 'Память 500 Гб' },
          { 'name': 'Память 1 Тб' },
          { 'name': 'Память 2 Тб' },

          { 'name': 'SSD' },
          { 'name': 'm.2' }
        ]

        # Для случаев, когда выбранной рекомендации нет в общем списке (для отображения на форме)
        data[:request]['recommendation_json'].try(:each) do |rec|
          next if data[:list_recommendations].include?(rec)

          data[:list_recommendations] << rec
        end
      end

      def transform_to_json
        data[:request] = data[:request].as_json(
          include: [
            :request_items,
            :attachments,
            {
              order: {
                include: {
                  operations: {
                    include: %i[item inv_items]
                  }
                }
              }
            }
          ]
        )

        workplace_count_id = Invent::WorkplaceCount.find_by(division: data[:request]['user_dept'])
        if workplace_count_id.present?
          data[:request]['freeze_ids'] = Invent::Workplace.where(status: :freezed).where(workplace_count_id: workplace_count_id).pluck(:workplace_id).join(', ')
        end

        data[:request]['status_translated'] = Request.translate_enum(:status, data[:request]['status'])
        data[:request]['request_items'].each do |item|
          item['properties_string'] = item['properties'].present? ? properties_string(item['properties']) : 'Отсутствует'
        end

        if data[:request]['attachments'].present?
          data[:request]['attachments'].each { |att| att['filename'] = att['document'].file.nil? ? 'Файл отсутствует' : att['document'].identifier }
        end

        data[:request]['recommendations'] = []
      end

      def properties_string(properties)
        properties.map do |prop|
          "#{prop['name']} - #{prop['value']}"
        end
      end
    end
  end
end
