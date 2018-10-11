require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe ExecuteOut, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      subject { ExecuteOut.new(current_user, order.id, order_params) }
      let!(:workplace) do
        wp = build(:workplace_pk, dept: ***REMOVED***)
        wp.save(validate: false)
        wp
      end
      let(:order_json) { order.as_json }

      context 'when operations without invent_num' do
        let(:first_item) { create(:used_item, count: 1, count_reserved: 1, item_model: 'Мышь', item_type: 'Logitech') }
        let(:sec_item) { create(:new_item, count: 3, count_reserved: 1, item_model: 'Клавиатура', item_type: 'OKLICK') }
        let(:first_op) { build(:order_operation, item: first_item, shift: -1) }
        let(:sec_op) { build(:order_operation, item: sec_item, shift: -1) }
        let(:operations) { [first_op, sec_op] }
        let!(:order) { create(:order, inv_workplace: workplace, operation: :out, operations: operations, validator_id_tn: current_user.id_tn) }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each { |op| op['status'] = 'done' }
          order_json
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
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              if index == 1
                op['status'] = 'done'

                op['inv_items_attributes'] = [{
                  id: sec_inv_item.item_id,
                  serial_num: '111111',
                  invent_num: sec_item.generate_invent_num
                }]
              end
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

          it 'changes count of selected items' do
            subject.run

            expect(sec_item.reload.count).to be_zero
            expect(sec_item.reload.count_reserved).to be_zero
          end

          it 'does not change status of non-selected item' do
            subject.run

            expect(first_inv_item.reload.status).to eq 'waiting_take'
          end

          it 'sets :in_workplace status selected item' do
            subject.run

            expect(sec_inv_item.reload.status).to eq 'in_workplace'
          end

          it 'sets serial_num to the each selected item' do
            subject.run

            expect(sec_inv_item.reload.serial_num).to eq '111111'
          end

          it 'sets invent_num to the each selected item' do
            subject.run

            expect(sec_inv_item.reload.invent_num).to eq sec_item.invent_num_start.to_s
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
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each do |op|
              op['status'] = 'done'

              operation = order.operations.find { |el| el.id == op['id'] }
              op['inv_items_attributes'] = operation.inv_items.as_json(only: [:item_id, :invent_num, :serial_num])
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
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each do |op|
              op['status'] = 'done'

              operation = order.operations.find { |el| el.id == op['id'] }
              op['inv_items_attributes'] = operation.inv_items.as_json(only: [:item_id, :invent_num, :serial_num])
              op['inv_items_attributes'].each do |inv_item|
                inv_item['id'] = inv_item['item_id']
                inv_item['invent_num'] = 777777
                inv_item.delete('item_id')
              end
            end
            order_json
          end

          include_examples 'execute_out failed specs'

          it 'does not change invent_num of selected items' do
            subject.run

            expect(first_inv_item.reload.invent_num).not_to eq 777777
          end
        end

        context 'and when workplace already has pc' do
          let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let(:inv_item) { create(:item, :with_property_values, workplace: workplace, type_name: :pc, status: :waiting_take, disable_filters: true) }
          let(:item) { create(:used_item, count_reserved: 1, inv_item: inv_item) }
          let(:operation) { build(:order_operation, item: item, inv_item_ids: [item.invent_item_id], shift: -1) }
          let!(:order) { create(:order, inv_workplace: workplace, operation: :out, validator_id_tn: current_user.id_tn, operations: [operation]) }
          let(:order_params) do
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = [operation].as_json
            order_json['operations_attributes'].each do |op|
              op['status'] = 'done'
              op['inv_items_attributes'] = operation.inv_items.as_json(only: [:item_id, :invent_num, :serial_num])
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
