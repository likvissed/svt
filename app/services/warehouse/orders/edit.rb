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
        data[:order] = Order.includes(operations: [:item, inv_items: %i[model type]]).find(@order_id)
        data[:operation] = Operation.new(operationable: data[:order], shift: 1)
      end

      def load_divisions
        data[:divisions] = Invent::WorkplaceCount.pluck(:division).sort_by(&:to_i)
      end

      # Получить список типов оборудования с их свойствами и возможными значениями.
      def load_types
        data[:eq_types] = Invent::Type.where('name != "unknown"')
      end

      def transform_to_json
        data[:order] = data[:order].as_json(
          include: [
            :consumer,
            operations: {
              methods: :formatted_date,
              include: [
                :item,
                inv_items: {
                  include: %i[model type],
                  methods: :full_item_model
                }
              ]
            }
          ]
        )

        data[:order]['operations_attributes'] = data[:order]['operations']
        data[:order].delete('operations')

        data[:order]['operations_attributes'].each do |op|
          next unless op['item']

          op['inv_item_ids'] = op['inv_items'].map { |io| io['item_id'] }
        end
      end

      def check_hosts
        data[:order]['operations_attributes'].each do |op|
          invent_num = op['inv_items'].any? ? op['inv_items'].first['invent_num'] : nil
          host_data = HostIss.by_invent_num(invent_num)
          op['unreg'] = host_data ? host_data['class'].to_i == 4 : nil
        end
      end
    end
  end
end
