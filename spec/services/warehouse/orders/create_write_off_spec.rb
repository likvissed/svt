require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateWriteOff, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      let(:item) { create(:item, :with_property_values, type_name: :monitor) }
      let(:invent_item_ids) { [item.item_id] }
      let!(:w_item_1) { create(:used_item, inv_item: item) }
      let!(:w_item_2) { create(:used_item, warehouse_type: :without_invent_num) }
      let(:operation_1) { attributes_for(:order_operation, item_id: w_item_1.id, shift: -1) }
      let(:operation_2) { attributes_for(:order_operation, item_id: w_item_2.id, shift: -1) }
      let(:order_params) do
        order = attributes_for(:order, operation: :write_off)
        order[:operations_attributes] = [operation_1, operation_2]
        order
      end
      subject { CreateWriteOff.new(current_user, order_params.as_json) }

      context 'and when :operation attribute is not :write_off' do
        let(:order_params) { attributes_for(:order, operation: :in) }

        its(:run) { is_expected.to be_falsey }
      end

      context 'and when :shift attribute of any operation has positive value' do
        let(:operation) { attributes_for(:order_operation, shift: 4) }
        let(:order_params) do
          order = attributes_for(:order, operation: :write_off)
          order[:operations_attributes] = [operation]
          order
        end

        it 'exit from service without processing params' do
          expect(subject).not_to receive(:init_order)
          subject.run
        end

        its(:run) { is_expected.to be_falsey }
      end

      context 'when item was not selected' do
        let(:order_params) do
          order = attributes_for(:order, operation: :write_off)
          order[:operations_attributes] = []
          order
        end

        its(:run) { is_expected.to be_falsey }
      end

      context 'when item is not used' do
        let(:new_item) { create(:new_item) }
        let(:operation) { attributes_for(:order_operation, item_id: new_item.id, shift: -1) }
        let(:order_params) do
          order = attributes_for(:order, operation: :write_off)
          order[:operations_attributes] = [operation]
          order
        end

        its(:run) { is_expected.to be_falsey }
      end

      its(:run) { is_expected.to be_truthy }

      it 'sets validator fields' do
        subject.run

        expect(Order.last.validator_id_tn).to eq current_user.id_tn
        expect(Order.last.validator_fio).to eq current_user.fullname
      end

      it 'creates warehouse_operations records' do
        expect { subject.run }.to change(Operation, :count).by(order_params[:operations_attributes].size)
      end

      it 'creates warehouse_item_to_orders records' do
        expect { subject.run }.to change(InvItemToOperation, :count).by(1)
      end

      it 'creates order' do
        expect { subject.run }.to change(Order, :count).by(1)
      end

      it 'changes :count_reserved of the each item' do
        subject.run

        2.times { |i| expect(send("w_item_#{i + 1}").reload.count_reserved).to eq 1 }
      end

      it 'does not create inv_item' do
        expect { subject.run }.not_to change(Invent::Item, :count)
      end

      it 'changes status to :waiting_write_off of the each selected item' do
        subject.run

        expect(item.reload.status).to eq 'waiting_write_off'
        expect(w_item_1.reload.status).to eq 'waiting_write_off'
      end

      context 'when invent_item was not updated' do
        before { allow_any_instance_of(Invent::Item).to receive(:save).and_return(false) }

        include_examples 'specs for failed on create :write_off order'
      end

      it 'broadcasts to write_off_orders' do
        expect(subject).to receive(:broadcast_write_off_orders)
        subject.run
      end

      it 'broadcasts to items' do
        expect(subject).to receive(:broadcast_items)
        subject.run
      end
    end
  end
end
