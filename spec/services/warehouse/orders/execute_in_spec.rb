require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe ExecuteIn, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      subject { ExecuteIn.new(current_user, order.warehouse_order_id, order_params) }

      context 'when operations belongs_to item' do
        let(:first_inv_item) { create(:item, :with_property_values, type_name: :pc, status: :waiting_bring) }
        let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor) }
        let(:workplace) do
          wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
          wp.save(validate: false)
          wp
        end
        let(:first_item) { create(:used_item, inv_item: first_inv_item, count: 0, count_reserved: 0) }
        let(:sec_item) { create(:used_item, inv_item: sec_inv_item, count: 0, count_reserved: 0) }
        let(:operations) do
          [
            build(:order_operation, item: first_item, invent_item_id: first_item.invent_item_id),
            build(:order_operation, item: sec_item, invent_item_id: sec_item.invent_item_id)
          ]
        end
        let!(:order) { create(:order, workplace: workplace, operations: operations, inv_items: [first_inv_item, sec_inv_item]) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each_with_index do |op, index|
            op['status'] = 'done' if index.zero?
            op['id'] = op['warehouse_operation_id']
            op['invent_item_id'] = operations.find { |el| el.warehouse_operation_id == op['id'] }.invent_item_id

            op.delete('warehouse_operation_id')
          end
          order_json
        end

        include_examples 'execute_in specs'

        it 'changes count of warehouse_items' do
          expect { subject.run }.to change { Item.first.count }.by(operations.first.shift)
        end

        it 'sets nil to the workplace and status attributes into the invent_item record' do
          subject.run

          expect(first_inv_item.reload.workplace).to be_nil
          expect(first_inv_item.reload.status).to be_nil
        end

        it 'does not set nil to the workplace into another invent_item records' do
          subject.run

          expect(sec_inv_item.reload.workplace).to eq workplace
        end

        context 'and when invent_item was not updated' do
          before { allow_any_instance_of(Invent::Item).to receive(:update_attributes!).and_raise(ActiveRecord::RecordNotSaved) }

          it 'does not save all another records' do
            subject.run

            expect(operations.first.reload.processing?).to be_truthy
            expect(operations.first.reload.stockman_fio).to be_nil
            expect(operations.first.reload.stockman_id_tn).to be_nil
            expect(order.reload.consumer_id_tn).to be_nil
            expect(order.reload.consumer_fio).to be_nil
            expect(first_item.reload.count).to be_zero
          end
        end

        context 'and when warehouse_item was not updated' do
          before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved) }

          it 'does not save all another records' do
            subject.run

            expect(operations.first.reload.processing?).to be_truthy
            expect(operations.first.reload.stockman_fio).to be_nil
            expect(operations.first.reload.stockman_id_tn).to be_nil
            expect(order.reload.consumer_id_tn).to be_nil
            expect(order.reload.consumer_fio).to be_nil
            expect(first_inv_item.reload.workplace).to eq workplace
          end
        end

        context 'and when order was not updated' do
          before do
            allow_any_instance_of(Order).to receive(:save).and_return(false)
            subject.run
          end

          it 'does not save all another records' do
            expect(operations.first.reload.processing?).to be_truthy
            expect(operations.first.reload.stockman_fio).to be_nil
            expect(operations.first.reload.stockman_id_tn).to be_nil
            expect(first_inv_item.reload.workplace).to eq workplace
            expect(first_item.reload.count).to be_zero
          end

          it 'adds fill error object with %i[object full_message] keys' do
            expect(subject.error).to include(:object, :full_message)
          end
        end

        context 'and when operations is not selected' do
          let(:order_params) do
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each do |op|
              op['id'] = op['warehouse_operation_id']
              op['invent_item_id'] = operations.find { |el| el.warehouse_operation_id == op['id'] }.invent_item_id

              op.delete('warehouse_operation_id')
            end
            order_json
          end

          it 'adds :operation_not_selected error' do
            subject.run

            expect(subject.error[:full_message]).to eq 'Необходимо выбрать хотя бы одну позицию'
          end
        end
      end

      context 'and when operations is not belong to item' do
        let(:first_op) { build(:order_operation, item_model: 'Мышь', item_type: 'Logitech') }
        let(:sec_op) { build(:order_operation, item_model: 'Клавиатура', item_type: 'OKLICK') }
        let(:operations) { [first_op, sec_op] }
        let!(:order) { create(:order, operations: operations) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each do |op|
            op['status'] = 'done'
            op['id'] = op['warehouse_operation_id']

            op.delete('warehouse_operation_id')
          end
          order_json
        end

        include_examples 'execute_in specs'

        it 'creates a new warehouse_item' do
          expect { subject.run }.to change(Item, :count).by(2)
        end

        it 'sets warehouse_item values from a corresponding operations' do
          subject.run

          [first_op, sec_op].each do |op|
            op.reload
            expect(op.item.warehouse_type).to eq 'without_invent_num'
            expect(op.item.item_type).to eq op.item_type
            expect(op.item.item_model).to eq op.item_model
            expect(op.item.used).to be_truthy
            expect(op.item.count).to eq op.shift
            expect(op.item.count_reserved).to be_zero
          end
        end

        context 'and when warehouse_item was not created' do
          before { allow_any_instance_of(Operation).to receive(:create_item!).and_raise { ActiveRecord::RecordNotSaved } }

          it 'does not save all another records' do
            subject.run

            [first_op.reload, sec_op.reload].each do |op|
              expect(op.processing?).to be_truthy
              expect(op.stockman_fio).to be_nil
              expect(op.stockman_id_tn).to be_nil
            end
            expect(order.reload.consumer_id_tn).to be_nil
            expect(order.reload.consumer_fio).to be_nil
          end

          it 'does not create item' do
            expect { subject.run }.not_to change(Item, :count)
          end

          its(:run) { is_expected.to be_falsey }
        end

        context 'and when order was not updated' do
          before { allow_any_instance_of(Order).to receive(:save).and_return(false) }

          it 'does not save all another records' do
            subject.run

            [first_op, sec_op].each do |op|
              expect(op.reload.processing?).to be_truthy
              expect(op.reload.stockman_fio).to be_nil
              expect(op.reload.stockman_id_tn).to be_nil
            end
          end

          it 'does not create item' do
            expect { subject.run }.not_to change(Item, :count)
          end

          its(:run) { is_expected.to be_falsey }
        end
      end

      context 'and when one of operations already done and another just selected' do
        let(:user) { create(:user) }
        let(:item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'Мышь', item_model: 'Logitech') }
        let(:first_op) { build(:order_operation, item_type: 'Мышь', item_model: 'Logitech', status: :done, item: item, stockman_id_tn: user.id_tn) }
        let(:sec_op) { build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK') }
        let(:operations) { [first_op, sec_op] }
        let!(:order) { create(:order, workplace: nil, operations: operations, consumer_tn: user.tn) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each do |op|
            op['status'] = 'done'
            op['id'] = op['warehouse_operation_id']

            op.delete('warehouse_operation_id')
          end
          order_json
        end

        its(:run) { is_expected.to be_truthy }
      end
    end
  end
end
