module Warehouse
  module Orders
    # Загрузить данные об ордере для редактирования
    class PrepareToDeliver < BaseService
      def initialize(current_user, order_id, order_params)
        @current_user = current_user
        @order_id = order_id
        @order_params = order_params

        super
      end

      def run
        find_order
        search_inv_items
        return false unless validate_order

        check_signs
        prepare_params

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_order
        @order = Order.includes(:inv_items, inv_workplace: { items: :binders }).find(@order_id)
        @order.assign_attributes(@order_params)
        authorize @order, :prepare_to_deliver?
      end

      def search_inv_items
        data[:selected_op] = @order.operations.select { |op| op.status_changed? && op.done? }
        data[:selected_op].each do |op|
          op.set_stockman(current_user)
          op.presence_w_receiver_fio = true
          op.re_stick_barcode = true
        end

        return true unless data[:selected_op].empty?

        error[:full_message] = I18n.t('activemodel.errors.models.warehouse/orders/execute.operation_not_selected')
        raise 'Техника не выбрана'
      end

      def validate_order
        return true if @order.valid?

        process_order_errors(@order)
        false
      end

      def check_signs
        # ids признаков подтвержденной техники на РМ
        data[:sign_ids_on_wp] = []
        @order.inv_workplace.items.each do |it|
          next unless it.status == 'in_workplace' && it.binders.present?

          # Сортируем для дальнейшего сравнения техники, которая исполняется
          data[:sign_ids_on_wp] = it.binders.map(&:sign_id).sort
        end
      end

      def prepare_params
        data[:operations_attributes] = @order.operations.includes(inv_items: [:model, property_values: :property_list], item: :location)
                                         .as_json(
                                           include: {
                                             item: { include: :binders },
                                             inv_items: {
                                               include: {
                                                 property_values: {
                                                   include: %i[property property_list]
                                                 }
                                               },
                                               methods: :short_item_model
                                             }
                                           }
                                         )
        data[:operations_attributes].each do |op|
          op['inv_items_attributes'] = op['inv_items']
          op['inv_items_attributes'].each do |inv_item|
            inv_item['property_values'].each do |prop_val|
              if prop_val['value'].present? && %w[date replacement_date].include?(prop_val['property']['name'])
                prop_val['value'] = Time.zone.parse(prop_val['value']).strftime('%d.%m.%Y')
              end
            end

            inv_item['id'] = inv_item['item_id']
            inv_item.delete('item_id')
          end

          if data[:selected_op].any? { |sel| sel.id == op['id'] }
            op['status'] = :done

            op['binders_for_execute_out'] = check_binders_for_item(op) if data[:sign_ids_on_wp].present?
          end

          op.delete('inv_items')
        end
        data[:selected_op] = data[:selected_op].as_json(only: :id)
      end

      def check_binders_for_item(operation)
        msg_signs_incorrect = '(признаки техники не соответствуют признакам на РМ )'

        return msg_signs_incorrect if operation['item']['binders'].blank?

        item_sign_ids = operation['item']['binders'].map { |bind| bind['sign_id'] }.sort

        data[:sign_ids_on_wp] == item_sign_ids ? ' ' : msg_signs_incorrect
      end
    end
  end
end
