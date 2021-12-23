module Warehouse
  module Requests
    # Отправить на подтверждение пользователю (Этап №4)
    class SendAnswerToUser < Warehouse::ApplicationService
      def initialize(current_user, request_id)
        @current_user = current_user
        @request_id = request_id

        super
      end

      def run
        load_request
        load_order_params
        generate_params_order
        # generate_report
        # send_file
        send_answer

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_request
        @request = Request.find(@request_id)

        authorize @request, :send_answer_to_user?
      end

      def load_order_params
        @order = Order.includes(:attachment, operations: [item: :location, inv_items: %i[model type]]).find(@request.order.id)

        @order_params = @order.as_json(
          include: {
            attachment: {},
            operations: {
              methods: %i[formatted_date to_write_off],
              include: [
                {
                  item: { include: :location }
                },
                {
                  inv_items: {
                    include: %i[model type],
                    methods: :full_item_model
                  }
                }
              ]
            },
            inv_workplace: {}
          }
        )
      end

      def generate_report
        # Массив id позиций, которые относятся к технике без инв. №
        warehouse_item_params = @order_params['operations'].select { |op| op['inv_items'].blank? && op['inv_item_ids'].blank? }.map { |op| op['id'] }

        date = @order.done? ? @order.closed_time : Time.zone.now
        l_date = I18n.l(date, format: '%d.%m.%Y')

        # Получение точно действительного токена
        UsersReference.new_token_hr

        report = Rails.root.join('lib', 'request_generate_order_report.php')
        command = "php #{report} #{Rails.env} #{@order.id} '#{@order_params['consumer_fio'] || @order_params['consumer_tn']}' '#{l_date}' '#{invent_item_params.to_json}' '#{warehouse_item_params.to_json}' '#{Rails.cache.read('token_hr')}'  '#{ENV['USERS_REFERENCE_URI_SEARCH']}' '#{@order.request_num}' '#{@request_id}'"
        @data = IO.popen(command)
      end

      def invent_item_params
        @order_params['operations'].map do |op|
          if op['inv_items']
            op['inv_items'].map { |inv_item| generate_invent_item_obj(inv_item['item_id'], inv_item['invent_num'], inv_item['serial_num']) }
          elsif op['inv_item_ids']
            op['inv_item_ids'].map { |inv_item_id| generate_invent_item_obj(inv_item_id) }
          end
        end.flatten.compact
      end

      def generate_invent_item_obj(id, invent_num = '', serial_num = '')
        {
          item_id: id,
          invent_num: invent_num,
          serial_num: serial_num
        }
      end

      def send_file
        t = Tempfile.new(['Шаблон_ордера_', '.rtf'])
        t << @data.read
        t.rewind

        file = File.new(t.path)

        Orbita.add_event(@request.request_id, @current_user.id_tn, 'add_files', { is_public: true }, [file])
      end

      def generate_params_order
        @ops_type_with_model = @order_params['operations'].map do |op|
          type = op['item_type'] || op['item']['item_type'] || op['inv_items'][0]['type']['short_description']
          model = op['item_model'] || op['item']['item_model'] || op['inv_items'][0]['full_item_model']
          count = op['shift'].abs

          "#{type}: #{model} (#{count} шт.)"
        end.join(', ')
      end

      def send_answer
        payload = {
          message: "Подтвердите, что вас устраивает получение вычислительной техники: #{@ops_type_with_model}",
          accept_endpoint: "https://#{ENV['APP_HOSTNAME']}.***REMOVED***.ru/api/v3/warehouse/requests/answer_from_user/#{@request_id}"
        }

        Orbita.add_event(@request.request_id, @current_user.id_tn, 'to_user_accept', payload)
      end
    end
  end
end
