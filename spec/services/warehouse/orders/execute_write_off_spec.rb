require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe ExecuteWriteOff, type: :model do
      before { allow_any_instance_of(Order).to receive(:set_consumer) }

      let!(:current_user) { create(:***REMOVED***_user) }
      let(:order_json) { order.as_json }
      subject { ExecuteWriteOff.new(current_user, order.id, order_params) }

      context 'when operations without invent_num' do
        let(:w_item) { create(:used_item, count: 1, warehouse_type: :without_invent_num, count_reserved: 1, item_model: 'Мышь', item_type: 'Logitech') }
        let(:operations) { [build(:order_operation, item: w_item, shift: -1)] }
        let!(:order) { create(:order, operation: :write_off, operations: operations, validator_id_tn: current_user.id_tn) }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each { |op| op['status'] = 'done' }
          order_json
        end

        include_examples 'execute_write_off specs'

        it 'changes count of selected items' do
          subject.run

          expect(w_item.reload.count).to be_zero
          expect(w_item.reload.count_reserved).to be_zero
        end

        %w[in out].each do |op_type|
          context "and when :operation attribute changes to :#{op_type}" do
            before { order_params['operation'] = op_type }

            include_examples 'order error format'
          end
        end

        context 'and when :shift attribute changes to positive value' do
          before { order_params['operations_attributes'].first['shift'] = 4 }

          include_examples 'order error format'
        end
      end

      context 'when operations with invent_num' do
        let(:inv_item_1) { create(:item, :with_property_values, type_name: :pc, status: :waiting_write_off) }
        let(:inv_item_2) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_write_off) }
        let(:w_item_1) { create(:used_item, count_reserved: 1, inv_item: inv_item_1, status: :waiting_write_off) }
        let(:w_item_2) { create(:used_item, count_reserved: 1, inv_item: inv_item_2, status: :waiting_write_off) }
        let(:operations) do
          [
            build(:order_operation, item: w_item_1, inv_item_ids: [inv_item_1.item_id], shift: -1),
            build(:order_operation, item: w_item_2, inv_item_ids: [inv_item_2.item_id], shift: -1)
          ]
        end
        let!(:order) { create(:order, operation: :write_off, operations: operations, validator_id_tn: current_user.id_tn) }
        let(:order_params) do
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each_with_index do |op, index|
            next unless index == 1

            op['status'] = 'done'
            op['inv_items_attributes'] = [id: inv_item_2.item_id]
          end
          order_json
        end

        it 'broadcasts to write_off_orders' do
          expect(subject).to receive(:broadcast_write_off_orders)

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

        include_examples 'execute_write_off specs'

        it 'changes count and count_reserved of selected items' do
          subject.run

          expect(w_item_2.reload.count).to be_zero
          expect(w_item_2.reload.count_reserved).to be_zero
        end

        it 'does not change status of non-selected item' do
          subject.run

          expect(inv_item_1.reload.status).to eq 'waiting_write_off'
          expect(w_item_1.reload.status).to eq 'waiting_write_off'
        end

        it 'sets :written_off status to the selected warehouse_items and associated invent_items' do
          subject.run

          expect(inv_item_2.reload.status).to eq 'written_off'
          expect(w_item_2.reload.status).to eq 'written_off'
        end
      end
    end
  end
end
