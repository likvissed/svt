module Warehouse
  module Requests
    # Загрузить список заявок
    class Index < Warehouse::ApplicationService
      def initialize(params)
        @params = params

        super
      end

      def run
        load_requests
        limit_records
        prepare_to_render

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_requests
        data[:recordsTotal] = Request.count
        @requests = Request.all.includes(:request_items, :attachments, :order) #.includes(:operations)
      end

      def limit_records
        data[:recordsFiltered] = @requests.count
        # @requests = @requests.order(request_id: :desc) #.limit(params[:length]).offset(params[:start])
      end

      def prepare_to_render
        # Rails.logger.info "@requests: #{@requests.inspect}".red
        data[:data] = @requests.as_json(include: %i[request_items attachments order]).each do |request|
          request['created_at'] = request['created_at'].strftime('%d-%m-%Y')
          request['status_translated'] = Request.translate_enum(:status, request['status'])
          request['category_translate'] = Request.translate_enum(:category, request['category'])

          request['request_items'].each do |item|
            item['properties_string'] = item['properties'].present? ? properties_string(item['properties']) : 'Отсутствует'
          end

          if request['attachments'].present?
            request['attachments'].each { |att| att['filename'] = att['document'].file.nil? ? 'Файл отсутствует' : att['document'].identifier }
          end
        end
      end

      def properties_string(properties)
        properties.map do |prop|
          "#{prop['name']} - #{prop['value']}"
        end
      end
    end
  end
end
