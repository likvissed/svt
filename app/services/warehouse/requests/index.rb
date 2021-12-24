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
        load_filters if need_init_filters?
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
        @requests = policy_scope(Request).includes(:request_items, :attachments, :order)
        run_filters if params[:filters]
      end

      def run_filters
        @requests = @requests.filter(filtering_params)
      end

      def filtering_params
        filters = JSON.parse(params[:filters])
        filters['for_statuses'] = data[:filters][:statuses].select { |filter| filter[:default] }.as_json if need_init_filters?
        filters.slice('request_id', 'order_id', 'category', 'for_statuses')
      end

      def limit_records
        data[:recordsFiltered] = @requests.length

        @requests = @requests.order(request_id: :desc).limit(params[:length]).offset(params[:start])
      end

      def load_filters
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
          request['label_status'] = label_status(request['status'])
          request['category_translate'] = Request.translate_enum(:category, request['category'])
        end
      end

      def label_status(status)
        case status
        when 'new'
          label_class = 'label-info'
        when 'analysis', 'create_order', 'in_work', 'ready'
          label_class = 'label-warning'
        when 'send_to_owner', 'check_order'
          label_class = 'label-primary'
        when 'reject'
          label_class = 'label-danger'
        when 'completed'
          label_class = 'label-success'
        when 'expected_in_stock', 'on_signature', 'waiting_confirmation_for_user'
          label_class = 'label-default'
        end

        "<span class='label #{label_class}'>#{Request.translate_enum(:status, status)}</span>"
      end
    end
  end
end
