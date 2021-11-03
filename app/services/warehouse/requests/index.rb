module Warehouse
  module Requests
    # Загрузить список заявок
    class Index < Warehouse::ApplicationService
      def initialize(current_user, params)
        @current_user = current_user
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
        @requests = Request.all.includes(:request_items, :attachments, :order)
      end

      def limit_records
        data[:recordsFiltered] = @requests.count

        # Отображаем для Работников только заявки, в каторых назначены только они
        @requests = @requests.where(executor_tn: @current_user.tn) if @current_user.role.name == 'worker'

        @requests = @requests.order(request_id: :asc).limit(params[:length]).offset(params[:start])
      end

      def prepare_to_render
        data[:data] = @requests.as_json(include: %i[request_items attachments order]).each do |request|
          request['created_at'] = request['created_at'].strftime('%d-%m-%Y')
          request['status_translated'] = Request.translate_enum(:status, request['status'])
          request['category_translate'] = Request.translate_enum(:category, request['category'])
        end
      end
    end
  end
end
