require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe ExecuteOut, type: :model do
      skip_users_reference

      let!(:current_user) { create(:***REMOVED***_user) }
      let(:consumer) { build(:***REMOVED***_user) }
      let!(:inv_item) { create(:item, :with_property_values, type_name: :printer, status: :in_workplace) }
      let!(:workplace) do
        w = build(:workplace_net_print, items: [inv_item], dept: ***REMOVED***)
        w.save(validate: false)
        w
      end
      let(:order_json) { order.as_json }
      before do
        allow_any_instance_of(Order).to receive(:set_consumer)
        allow_any_instance_of(Order).to receive(:present_user_iss)
      end
      subject { ExecuteOut.new(current_user, order.id, order_params) }

      context 'when operations without invent_num' do
        let(:first_item) { create(:used_item, count: 1, count_reserved: 1, item_model: 'Мышь', item_type: 'Logitech') }
        let(:sec_item) { create(:new_item, count: 3, count_reserved: 1, item_model: 'Клавиатура', item_type: 'OKLICK') }
        let(:first_op) { build(:order_operation, item: first_item, shift: -1) }
        let(:sec_op) { build(:order_operation, item: sec_item, shift: -1) }
        let(:operations) { [first_op, sec_op] }
        let!(:order) { create(:order, inv_workplace: workplace, operation: :out, operations: operations, validator_id_tn: current_user.id_tn) }
        let(:order_params) do
          order_json['consumer_tn'] = consumer['tn']
          order_json['consumer_fio'] = consumer['fullname']
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each { |op| op['status'] = 'done' }
          order_json
        end

        context 'and when have item for assign barcode' do
          let(:third_item) { create(:used_item, warehouse_type: :without_invent_num, count: 2, count_reserved: 1, item_type: 'Картридж', item_model: '6515DNI', status: 'non_used') }
          let(:third_op) { build(:order_operation, item: third_item, shift: -1) }
          let(:operations) { [first_op, sec_op, third_op] }
          let(:new_warehouse_item) { Item.last }
          let(:new_invent_prop_value) { Invent::PropertyValue.last }
          let(:preperty_id) { Invent::Property.find_by(short_description: new_warehouse_item.item_type.capitalize).property_id }

          before { order_params[:invent_num] = workplace.items.first.invent_num }

          it 'count warehouse_item increased' do
            expect { subject.run }.to change(Item, :count).by(1)
          end

          it 'created warehouse_item with fields item operation' do
            subject.run

            expect(new_warehouse_item.warehouse_type).to eq third_op.item.warehouse_type
            expect(new_warehouse_item.item_type).to eq third_op.item.item_type
            expect(new_warehouse_item.item_model).to eq third_op.item.item_model
            expect(new_warehouse_item.barcode).to eq third_op.item.barcode
            expect(new_warehouse_item.status).to eq 'used'
            expect(new_warehouse_item.count).to be_zero
          end

          it 'count barcode increased' do
            expect { subject.run }.to change(Barcode, :count).by(1)
          end

          it 'created barcode for new warehouse_item' do
            subject.run

            expect(Barcode.last.codeable_type).to eq third_op.item.class.name
            expect(Barcode.last.codeable_id).to eq new_warehouse_item.id
          end

          it 'count Invent::PropertyValue increased' do
            expect { subject.run }.to change(Invent::PropertyValue, :count).by(1)
          end

          it 'created Invent::PropertyValue for new warehouse_item' do
            subject.run

            expect(new_invent_prop_value.property_id).to eq preperty_id
            expect(new_invent_prop_value.item_id).to eq workplace.items.first.item_id
            expect(new_invent_prop_value.value).to eq "#{new_warehouse_item.item_model} (#{new_warehouse_item.barcode_item.id})"
            expect(new_invent_prop_value.warehouse_item_id).to eq new_warehouse_item.id
          end

          context 'and when the w_item has an count equal to 1' do
            let!(:third_item) { create(:used_item, warehouse_type: :without_invent_num, count: 1, count_reserved: 1, item_type: 'Картридж', item_model: '6515DNI', status: 'non_used') }

            it 'count warehouse_item not change' do
              expect { subject.run }.not_to change(Item, :count)
            end

            it 'present w_item is destroyed and call exeception' do
              subject.run

              expect { third_item.reload }.to raise_exception(ActiveRecord::RecordNotFound)
            end

            context 'and when status warehouse_item is used' do
              before { third_item.status = 'used' }

              it 'count warehouse_item not increased' do
                expect { subject.run }.not_to change(Item, :count)
              end

              it 'sets status, count and count_reserved for third_item' do
                subject.run

                expect(Item.last.status).to eq third_op.item.status
                expect(Item.last.count).to be_zero
                expect(Item.last.count_reserved).to be_zero
              end
            end
          end

          context 'and when the w_item has an count equal to 2 and supply' do
            let(:supply) { create(:supply) }
            let(:supply_operation) { create(:supply_operation, operationable: supply, shift: 2) }

            let!(:third_item) { create(:used_item, warehouse_type: :without_invent_num, count: 2, count_reserved: 2, item_type: 'Картридж', item_model: '6515DNI', status: 'non_used') }
            let(:third_op) { build(:order_operation, item: third_item, shift: -2) }

            before { third_item.operations = [supply_operation] }

            it 'created two new w_item and destroy one old w_item' do
              expect { subject.run }.to change(Item, :count).by(1)
            end

            it 'created four new and destroy two old Operation' do
              expect { subject.run }.to change(Operation, :count).by(2)
            end

            it 'sets fields in operations for new items' do
              subject.run

              Item.last(2).each do |it|
                expect(it.operations.first.operationable_type).to eq third_op.operationable_type
                expect(it.operations.first.status).to eq 'done'
                expect(it.operations.first.item_type).to eq third_item.item_type
                expect(it.operations.first.item_model).to eq third_item.item_model
                expect(it.operations.first.shift).to eq(-1)

                expect(it.operations.last.operationable_type).to eq supply_operation.operationable_type
                expect(it.operations.last.status).to eq 'done'
                expect(it.operations.last.item_type).to eq third_item.item_type
                expect(it.operations.last.item_model).to eq third_item.item_model
                expect(it.operations.last.shift).to eq 1
              end
            end

            it 'sets status, count and count_reserved for new w_item' do
              subject.run

              Item.last(2).each do |it|
                expect(it.status).to eq 'used'
                expect(it.count).to be_zero
                expect(it.count_reserved).to be_zero
              end
            end

            it 'order status is done' do
              subject.run

              expect(order.reload.status).to eq 'done'
            end

            it 'status is done for all operations order' do
              subject.run

              order.reload.operations.each do |op|
                expect(op.status).to eq 'done'
              end
            end

            it 'present w_item and supply is destroyed and call exeception' do
              subject.run

              expect { third_item.reload }.to raise_exception(ActiveRecord::RecordNotFound)
              expect { supply_operation.reload }.to raise_exception(ActiveRecord::RecordNotFound)
            end
          end
        end

        include_examples 'execute_out specs'

        it 'changes count of selected items' do
          subject.run

          expect(first_item.reload.count).to be_zero
          expect(first_item.reload.count_reserved).to be_zero
          expect(sec_item.reload.count).to eq 2
          expect(sec_item.reload.count_reserved).to be_zero
        end

        context 'and when :operation attribute changes to :in' do
          before { order_params['operation'] = 'in' }

          include_examples 'order error format'
        end

        context 'and when :shift attribute changes to positive value' do
          before { order_params['operations_attributes'].first['shift'] = 4 }

          include_examples 'order error format'
        end
      end

      context 'when operations with invent_num' do
        context 'and when item has valid property_values' do
          let(:first_inv_item) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take) }
          let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_take) }
          let(:workplace) do
            wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
            wp.save(validate: false)
            wp
          end
          let(:first_item) { create(:used_item, count_reserved: 1, inv_item: first_inv_item) }
          let(:sec_item) { create(:used_item, count_reserved: 1, inv_item: sec_inv_item) }
          let(:operations) do
            [
              build(:order_operation, item: first_item, inv_item_ids: [first_item.invent_item_id], shift: -1),
              build(:order_operation, item: sec_item, inv_item_ids: [sec_item.invent_item_id], shift: -1)
            ]
          end
          let(:inv_items) { [first_inv_item, sec_inv_item] }
          let!(:order) { create(:order, inv_workplace: workplace, operation: :out, operations: operations, validator_id_tn: current_user.id_tn) }
          let(:order_params) do
            order_json['consumer_tn'] = consumer['tn']
            order_json['consumer_fio'] = consumer['fullname']
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              next unless index == 1

              op['status'] = 'done'
              op['inv_items_attributes'] = [{
                id: sec_inv_item.item_id,
                serial_num: '111111',
                invent_num: sec_item.generate_invent_num
              }]
            end
            order_json
          end

          it 'broadcasts to out_orders' do
            expect(subject).to receive(:broadcast_out_orders)
            subject.run
          end

          it 'broadcasts to archive_orders' do
            expect(subject).to receive(:broadcast_archive_orders)
            subject.run
          end

          it 'broadcasts to items' do
            expect(subject).to receive(:broadcast_items)
            subject.run
          end

          it 'broadcasts to workplaces_list' do
            expect(subject).to receive(:broadcast_workplaces_list)
            subject.run
          end

          include_examples 'execute_out specs'

          it 'does not change count of non-selected items' do
            expect(first_item.reload.count).to eq 1
            expect(sec_item.reload.count_reserved).to eq 1
          end

          it 'changes count and count_reserved of selected items' do
            subject.run

            expect(sec_item.reload.count).to be_zero
            expect(sec_item.reload.count_reserved).to be_zero
          end

          it 'does not change status of non-selected item' do
            subject.run

            expect(first_inv_item.reload.status).to eq 'waiting_take'
          end

          it 'sets :in_workplace status to the selected items' do
            subject.run

            expect(sec_inv_item.reload.status).to eq 'in_workplace'
          end

          it 'sets serial_num to the selected item' do
            subject.run

            expect(sec_inv_item.reload.serial_num).to eq '111111'
          end

          it 'sets invent_num to the selected item' do
            subject.run

            expect(sec_inv_item.reload.invent_num).to eq sec_item.invent_num_start.to_s
          end

          context 'and when serial num is nil for type item in constant :NAME_FOR_MANDATORY_SERIAL_NUM' do
            before do
              order_params['operations_attributes'].each { |op| op['inv_items_attributes'].first[:serial_num] = nil if op['inv_items_attributes'] }
            end

            its(:run) { is_expected.to be_falsey }
          end
        end

        context 'and when one of items does not have valid property' do
          let(:first_inv_item) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take, invent_num: nil, disable_filters: true) }
          let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_take, invent_num: nil, disable_filters: true) }
          let(:workplace) do
            wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
            wp.save(validate: false)
            wp
          end
          let(:first_item) { create(:used_item, count_reserved: 1, inv_item: first_inv_item) }
          let(:sec_item) { create(:used_item, count_reserved: 1, inv_item: sec_inv_item) }
          let(:operations) do
            [
              build(:order_operation, item: first_item, inv_item_ids: [first_item.invent_item_id], shift: -1),
              build(:order_operation, item: sec_item, inv_item_ids: [sec_item.invent_item_id], shift: -1)
            ]
          end
          let(:inv_items) { [first_inv_item, sec_inv_item] }
          let!(:order) { create(:order, inv_workplace: workplace, operation: :out, operations: operations, validator_id_tn: current_user.id_tn) }
          let(:order_params) do
            order_json['consumer_tn'] = consumer['tn']
            order_json['consumer_fio'] = consumer['fullname']
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each do |op|
              op['status'] = 'done'

              operation = order.operations.find { |el| el.id == op['id'] }
              op['inv_items_attributes'] = operation.inv_items.as_json(only: %i[item_id invent_num serial_num])
              op['inv_items_attributes'].each do |inv_item|
                inv_item['id'] = inv_item['item_id']
                inv_item.delete('item_id')
              end
            end

            order_json
          end

          include_examples 'execute_out failed specs'

          it 'does not change invent_num of selected items' do
            subject.run

            expect(first_inv_item.reload.invent_num).to be_nil
          end
        end

        context 'and when one of item does not have valid property_values' do
          let(:first_inv_item) do
            i = build(:item, :without_property_values, type_name: :pc, status: :waiting_take, disable_filters: true)
            i.save(validate: false)
            i
          end
          let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_take) }
          let(:workplace) do
            wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
            wp.save(validate: false)
            wp
          end
          let(:first_item) { create(:used_item, count_reserved: 1, item_model: 'Unit', inv_item: first_inv_item) }
          let(:sec_item) { create(:used_item, count_reserved: 1, inv_item: sec_inv_item) }
          let(:operations) do
            [
              build(:order_operation, item: first_item, inv_item_ids: [first_inv_item.item_id], shift: -1),
              build(:order_operation, item: sec_item, inv_item_ids: [sec_inv_item.item_id], shift: -1)
            ]
          end
          let(:inv_items) { [first_inv_item, sec_inv_item] }
          let!(:order) do
            o = build(:order, inv_workplace: workplace, operation: :out, operations: operations, validator_id_tn: current_user.id_tn)
            o.save(validate: false)
            o
          end
          let(:order_params) do
            order_json['consumer_tn'] = consumer['tn']
           order_json['consumer_fio'] = consumer['fullname']
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each do |op|
              op['status'] = 'done'

              operation = order.operations.find { |el| el.id == op['id'] }
              op['inv_items_attributes'] = operation.inv_items.as_json(only: %i[item_id invent_num serial_num])
              op['inv_items_attributes'].each do |inv_item|
                inv_item['id'] = inv_item['item_id']
                inv_item['invent_num'] = 777_777
                inv_item.delete('item_id')
              end
            end
            order_json
          end

          include_examples 'execute_out failed specs'

          it 'does not change invent_num of selected items' do
            subject.run

            expect(first_inv_item.reload.invent_num).not_to eq 777_777
          end
        end

        context 'and when workplace already has pc' do
          let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let(:inv_item) { create(:item, :with_property_values, workplace: workplace, type_name: :pc, status: :waiting_take, disable_filters: true) }
          let(:item) { create(:used_item, count_reserved: 1, inv_item: inv_item) }
          let(:operation) { build(:order_operation, item: item, inv_item_ids: [item.invent_item_id], shift: -1) }
          let!(:order) { create(:order, inv_workplace: workplace, operation: :out, validator_id_tn: current_user.id_tn, operations: [operation]) }
          let(:order_params) do
            order_json['consumer_tn'] = consumer['tn']
            order_json['consumer_fio'] = consumer['fullname']
            order_json['operations_attributes'] = [operation].as_json
            order_json['operations_attributes'].each do |op|
              op['status'] = 'done'
              op['inv_items_attributes'] = operation.inv_items.as_json(only: %i[item_id invent_num serial_num])
              op['inv_items_attributes'].each do |inv_item|
                inv_item['id'] = inv_item['item_id']
                inv_item.delete('item_id')
              end
            end
            order_json
          end

          its(:run) { is_expected.to be_truthy }
        end
      end
    end
  end
end
