module Warehouse
  module Orders
    # Загрузить данные об ордере для редактирования
    class Edit < BaseService
      def initialize(order_id, check_unreg = false)
        @order_id = order_id
        @check_unreg = check_unreg

        super
      end

      def run
        load_order
        load_divisions
        load_types
        transform_to_json
        check_hosts if @check_unreg.to_s == 'true'

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_order
        @order = Order.includes(:attachment, operations: [item: :location, inv_items: %i[model type]]).find(@order_id)
        data[:operation] = Operation.new(operationable: @order, shift: 1)
      end

      def load_divisions
        data[:divisions] = Invent::WorkplaceCount.pluck(:division).sort_by(&:to_i)
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_types
        data[:eq_types] = Invent::Type.all
      end

      def transform_to_json
        data[:order] = @order.as_json(
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
        data[:order]['operations_attributes'] = data[:order]['operations']

        data[:order]['fio_employee'] = @order.find_employee_by_workplace.first.try(:[], 'fullName')
        data[:order]['consumer'] ||= @order.consumer_from_history

        data[:order].delete('inv_workplace')

        data[:order].delete('operations')
        data[:order]['consumer'] ||= @order.consumer_from_history

        data[:order]['operations_attributes'].each do |op|
          op['operations_warehouse_receiver'] = Order::LIST_TYPE_FOR_ASSIGN_OP_RECEIVER.include?(op['item_type'].to_s.downcase) ? true : false

          next unless op['item']

          op['inv_item_ids'] = op['inv_items'].map { |io| io['item_id'] }
          op['item']['assign_barcode'] = Invent::Property::LIST_TYPE_FOR_BARCODES.include?(op['item']['item_type'].to_s.downcase) ? true : false
        end

        data[:order]['attachment_order'] = data[:order]['attachment'].present? ? true : false
        data[:order].delete('attachment')

        data[:order]['valid_op_warehouse_receiver_fio'] = @order.valid_op_warehouse_receiver_fio
      end

      def check_hosts
        data[:order]['operations_attributes'].each do |op|
          invent_num = if op['inv_items'].any?
                         Invent::Type::NAME_TYPE_OF_HOST.include?(op['inv_items'].first['type']['name']) ? op['inv_items'].first['invent_num'] : nil
                       else
                         nil
                       end

          host_data = HostIss.by_invent_num(invent_num)
          op['unreg'] = host_data ? host_data['class'].to_i == 4 : nil
        end
      end
    end
  end
end
