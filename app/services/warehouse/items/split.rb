module Warehouse
  module Items
    class Split < Warehouse::ApplicationService
      def initialize(current_user, item_id, items_attributes)
        @current_user = current_user
        @item_id = item_id
        @items_attributes = items_attributes

        super
      end

      def run
        present_count_for_invent_num
        find_item
        fill_with_new_data
        broadcast_items

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def present_count_for_invent_num
        return false if @items_attributes.any? { |item| item['count_for_invent_num'].blank? }
      end

      def find_item
        @item = Item.find(@item_id)
        authorize @item, :update?
      end

      def fill_with_new_data
        @item_for_update = []
        # Массив, содержащий инв.№, входящие в диапазон разделяемой техники, исключая инв.№ уже существующей техники
        array_invent_num = allowed_invent_num if @item.invent_num_start
        current_index = 0

        @items_attributes.each_with_index do |item, index|
          current_item = if index.zero?
                           @item.as_json
                         else
                           old_item = @item.as_json
                           old_item['id'] = ''
                           old_item['count_reserved'] = 0

                           item['property_values_attributes'].each { |prop_val| prop_val['id'] = '' } if item['property_values_attributes'].present?
                           old_item
                         end

          if array_invent_num.present?
            if current_item['count_reserved'].zero?
              current_item['invent_num_start'] = array_invent_num[current_index]
              current_item['invent_num_end'] = array_invent_num[current_index + item['count_for_invent_num'].to_i - 1]
            else
              # Добавление в диапазон инв.№ тех, которые еще не исполнены в расходных ордерах
              invent_num_waiting_take = [array_invent_num[current_index]]
              @item.operations.each do |op|
                op.inv_items.each { |inv_item| invent_num_waiting_take.push(inv_item.invent_num.to_i) if inv_item.status == 'waiting_take' }
              end

              current_item['invent_num_start'] = invent_num_waiting_take.sort.first
              current_item['invent_num_end'] = invent_num_waiting_take.sort.last
            end

            current_index += item['count_for_invent_num'].to_i
          end

          current_item['count'] = if current_item['count_reserved'].zero?
                                    item['count_for_invent_num']
                                  else
                                    item['count_for_invent_num'] + item['count_reserved']
                                  end

          current_item['location_attributes'] = item['location'].as_json
          current_item['property_values_attributes'] = item['property_values_attributes'].as_json

          @item_for_update.push(current_item)
        end

        if validation
          @item_for_update.each { |it| update_w_item(it) }
        end
      end

      def allowed_invent_num
        existing_invent_nums = Invent::Item.pluck(:invent_num)

        (@item.invent_num_start..@item.invent_num_end).to_a.reject { |el| existing_invent_nums.include?(el.to_s) }
      end

      def validation
        count_inc = 0

        @item_for_update.each do |item|
          if item['location_attributes']['room_id'] == -1
            name = item['location_attributes']['name']
            # Добавление тестовой комнаты на время проверки валидации техники
            item['location_attributes']['room_id'] = 2
          end
          item['location_attributes'].delete 'name'

          it = Item.new(item)
          it.allow_create_item = true

          if it.valid?
            count_inc += 1
            if name.present?
              item['location_attributes']['name'] = name
              item['location_attributes']['room_id'] = -1
            end
          else
            error[:full_message] = it.errors.full_messages.join('. ')
            raise 'Техника не разделена'
          end
        end

        return true if count_inc == @item_for_update.count
        false
      end

      def update_w_item(item)
        # Если существующая техника - то обновить, если новая - создать с расположением
        item['allow_create_item'] = true
        item_obj = if item['id'].present?
                     old_item = Items::Update.new(@current_user, item['id'], item)
                     old_item.run
                     old_item.data[:item]
                   else
                     item.delete 'create_time'
                     item.delete 'modify_time'

                     new_item = Items::Create.new(@current_user, item)
                     new_item.run
                     new_item.data[:item]
                   end

        create_or_update_operation(item_obj)
      end

      def create_or_update_operation(item_obj)
        supply_id = @item.supplies.first.id if @item.supplies.present?

        # Флаг, по которому отпределяем, была ли обновлена операция
        flag = true

        operation = item_obj.operations.build(
          item_id: item_obj['id'],
          shift: item_obj['count'],
          status: :processing,
          operationable_id: supply_id,
          operationable_type: 'Warehouse::Supply',
          item_type: item_obj['item_type'],
          item_model: item_obj['item_model'],
          date: Time.zone.now
        )
        operation.set_stockman(current_user)

        if @item.id == item_obj['id']
          op = item_obj.operations.first

          if op.present?
            operation['id'] = op.id
            op.update(operation.as_json)

            flag = false
          end
        end

        operation.save if flag
      end
    end
  end
end
