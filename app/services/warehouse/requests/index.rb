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
        init_filters
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
        @requests = policy_scope(Request).includes(:request_items, :attachments, :order)
        run_filters if params[:filters]
      end

      def run_filters
        @requests = @requests.filter(filtering_params)
      end

      def filtering_params
        JSON.parse(params[:filters]).slice('request_id', 'order_id', 'category', 'for_statuses')
      end

      def limit_records
        data[:recordsFiltered] = @requests.length

        @requests = @requests.order(request_id: :desc).limit(params[:length]).offset(params[:start])
      end

      def init_filters
        data[:filters] = {}
        data[:filters][:categories] = Request.categories.map { |key, _val| [key, Request.translate_enum(:category, key)] }.to_h
        data[:filters][:statuses] = request_statuses
      end

      def request_statuses
        statuses = Request.statuses.map { |key, val| { id: val, status: key, label: Request.translate_enum(:status, key) } }
        statuses.each { |status| status[:default] = Request::DEFAULT_STATUS_FILTER.include?(status[:status]) }
        statuses
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
