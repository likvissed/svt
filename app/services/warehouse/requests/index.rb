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
        @requests = Request.all.as_json #.includes(:operations)
      end

      def limit_records
        data[:recordsFiltered] = @requests.count
        # @requests = @requests.order(request_id: :desc) #.limit(params[:length]).offset(params[:start])
      end

      def prepare_to_render
        data[:data] = @requests.each do |request| #.as_json(include: :operations)
          request['created_at'] = request['created_at'].strftime('%d-%m-%Y')
          request['status_translated'] = Request.translate_enum(:status, request['status'])
          request['category_translate'] = Request.translate_enum(:category, request['category'])
        end
      end
    end
  end
end
