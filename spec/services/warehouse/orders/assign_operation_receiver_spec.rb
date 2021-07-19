require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe AssignOperationReceiver, type: :model do
      before do
        allow_any_instance_of(Order).to receive(:set_consumer).and_return([employee])
        allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([employee])
      end
      let(:employee) { build(:emp_***REMOVED***) }

      let(:user) { create(:***REMOVED***_user, role: role) }
      let(:operation_one) { build(:order_operation, item: item_one, shift: -1) }
      let(:operation_two) { build(:order_operation, item: item_two, shift: -1) }
      let(:order) { create(:order, operation: :out, validator_id_tn: user.id_tn, operations: [operation_one, operation_two]) }
      let(:receiver_fio) { 'Example FIO' }
      let(:order_json) { order.as_json }
      subject { AssignOperationReceiver.new(user, order.id, order_params) }

      context 'when all items is not used' do
        let(:item_one) { create(:new_item) }
        let(:item_two) { create(:new_item) }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'].first['warehouse_receiver_fio'] = receiver_fio
          order_json
        end

        context 'and when user with role manager' do
          let(:role) { create(:manager_role) }

          include_examples 'assigned warehouse_receiver_fio'
        end

        context 'and when user with role worker' do
          let(:role) { create(:worker_role) }

          its(:run) { is_expected.to be_falsey }

          it 'not changed warehouse_receiver_fio for all operations' do
            subject.run

            expect(operation_one.reload.warehouse_receiver_fio).to be_nil
            expect(operation_two.reload.warehouse_receiver_fio).to be_nil
          end
        end
      end

      context 'when all items is used' do
        let(:item_one) { create(:used_item) }
        let(:item_two) { create(:used_item) }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'].first['warehouse_receiver_fio'] = receiver_fio
          order_json
        end

        context 'and when user with role manager' do
          let(:role) { create(:manager_role) }

          include_examples 'assigned warehouse_receiver_fio'
        end

        context 'and when user with role worker' do
          let(:role) { create(:worker_role) }

          include_examples 'assigned warehouse_receiver_fio'
        end
      end

      context 'when the order contains operation with status is done' do
        let(:role) { create(:manager_role) }
        let(:item_one) { create(:new_item) }
        let(:item_two) { create(:used_item) }
        let!(:order) { create(:order, operation: :out, validator_id_tn: user.id_tn, consumer_id_tn: user.id_tn, operations: [operation_one, operation_two]) }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'].second['warehouse_receiver_fio'] = receiver_fio
          order_json
        end
        before do
          operation_one.stockman_fio = user.fullname
          operation_one.status = 'done'
        end

        its(:run) { is_expected.to be_truthy }

        it 'changed warehouse_receiver_fio for operation_two' do
          subject.run

          expect(operation_one.reload.warehouse_receiver_fio).to be_nil
          expect(operation_two.reload.warehouse_receiver_fio).to eq receiver_fio
        end

        it 'status has not changed for operations' do
          subject.run

          expect(order.operations.first.status).to eq operation_one.status
          expect(order.operations.second.status).to eq operation_two.status
        end
      end
    end
  end
end
