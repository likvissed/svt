require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe UpdateWriteOff, type: :model do
      skip_users_reference

      let(:user) { create(:user) }
      let(:new_user) { create(:***REMOVED***_user, role: create(:manager_role)) }
      let(:old_item) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_write_off) }
      let(:old_w_item_1) { create(:used_item, inv_item: old_item, status: :waiting_write_off, count_reserved: 1) }
      let(:old_w_item_2) { create(:used_item, item_type: 'Клавиатура', item_model: 'OKLICK', status: :waiting_write_off, count_reserved: 1) }
      let(:old_op_1) { build(:order_operation, item: old_w_item_1, inv_items: [old_item], shift: -1) }
      let(:old_op_2) { build(:order_operation, item: old_w_item_2, shift: -1) }
      let!(:order) { create(:order, operation: :write_off, operations: [old_op_1, old_op_2]) }
      let(:order_json) { order.as_json }
      subject { UpdateWriteOff.new(new_user, order.id, order_params) }

      context 'when :operation attribute changes to :out' do
        let(:order_params) { order_json.tap { |o| o['operation'] = 'out' } }

        include_examples 'order error format'
      end

      context 'when added a new operations' do
        let!(:item) { create(:item, :with_property_values, type_name: :pc, status: :in_stock) }
        let!(:w_item_1) { create(:used_item, inv_item: item) }
        let!(:w_item_2) { create(:used_item, item_type: 'Флэш-накопитель', item_model: 'Silicon Power') }
        let(:new_operation_1) { attributes_for(:order_operation, item_id: w_item_1.id, shift: -1) }
        let(:new_operation_2) { attributes_for(:order_operation, item_id: w_item_2.id, shift: -1) }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'] << new_operation_1.as_json
          order_json['operations_attributes'] << new_operation_2.as_json

          order_json
        end

        include_examples 'updating :write_off order'

        it 'creates added operations' do
          expect { subject.run }.to change(Operation, :count).by(2)
        end

        it 'creates InvItemToOperation records' do
          expect { subject.run }.to change(InvItemToOperation, :count).by(1)
        end

        it 'changes :count_reserved of the each item' do
          subject.run

          2.times { |i| expect(send("w_item_#{i + 1}").reload.count_reserved).to eq 1 }
        end

        it 'changes status to :waiting_write_off for selected item' do
          subject.run

          expect(item.reload.status).to eq 'waiting_write_off'
          2.times { |i| expect(send("w_item_#{i + 1}").reload.status).to eq 'waiting_write_off' }
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to write_off_orders' do
          expect(subject).to receive(:broadcast_write_off_orders)
          subject.run
        end

        context 'and when item was not updated' do
          before { allow_any_instance_of(Item).to receive(:save).and_return(false) }

          include_examples 'failed updating :write_off order'

          it 'does not change statuses of items' do
            subject.run

            expect(item.reload.status).to eq 'in_stock'
            2.times { |i| expect(send("w_item_#{i + 1}").reload.status).to eq 'used' }
          end

          it 'does not change :count_reserved attribute of items' do
            subject.run

            2.times { |i| expect(send("w_item_#{i + 1}").reload.count_reserved).to eq 0 }
          end
        end
      end

      context 'when removed operation' do
        let!(:removed_w_item) { Item.first }
        let!(:removed_i_item) { removed_w_item.inv_item }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'].each_with_index do |op, index|
            op['_destroy'] = 1 if index.zero?
          end

          order_json
        end

        include_examples 'updating :write_off order'

        it 'removed operation' do
          expect { subject.run }.to change(Operation, :count).by(-1)
        end

        it 'removed InvItemToOperation record' do
          expect { subject.run }.to change(InvItemToOperation, :count).by(-1)
        end

        it 'changes :count_reserved of the each item' do
          subject.run

          expect(removed_w_item.reload.count_reserved).to be_zero
        end

        it 'changes status to :used for associated warehouse_item' do
          subject.run

          expect(removed_w_item.reload.status).to eq 'used'
          expect(Item.last.status).to eq 'waiting_write_off'
        end

        it 'changes status to :in_stock for associated inv_items' do
          subject.run

          expect(removed_i_item.reload.status).to eq 'in_stock'
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to write_off_orders' do
          expect(subject).to receive(:broadcast_write_off_orders)
          subject.run
        end

        context 'when order was not updated' do
          before { allow_any_instance_of(Order).to receive(:save).and_return(false) }

          include_examples 'failed updating :writeOff on del'
        end

        context 'when item was not updated' do
          before { allow_any_instance_of(Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

          include_examples 'failed updating :writeOff on del'
        end

        context 'when invent_item was not updated' do
          before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

          include_examples 'failed updating :writeOff on del'
        end
      end
    end
  end
end
