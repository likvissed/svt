require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateByInvItem, type: :model do
      let!(:current_user) { create(:user) }
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let(:inv_item) { workplace.items.first }
      before { Invent::Item.update_all(priority: :high) }

      context 'and when :operation attribute is :out' do
        subject { CreateByInvItem.new(current_user, inv_item, :out) }

        its(:run) { is_expected.to be_falsey }
      end

      context 'when operation is :in' do
        subject { CreateByInvItem.new(current_user, inv_item, :in) }

        its(:run) { is_expected.to be_truthy }

        it 'creates warehouse_operation records' do
          expect { subject.run }.to change(Operation, :count).by(1)
        end

        it 'creates warehouse_item_to_orders records' do
          expect { subject.run }.to change(InvItemToOperation, :count).by(1)
        end

        it 'sets :done to the operation attribute' do
          subject.run

          Order.all.includes(:operations).each do |o|
            o.operations.each do |op|
              expect(op.status).to eq 'done'
            end
          end
        end

        it 'sets stockman to the each operation' do
          subject.run

          Order.all.includes(:operations).each do |o|
            o.operations.each do |op|
              expect(op.stockman_id_tn).to eq current_user.id_tn
              expect(op.stockman_fio).to eq current_user.fullname
            end
          end
        end

        it 'sets :done to the order status' do
          subject.run

          Order.all.each { |o| expect(o.done?).to be_truthy }
        end

        it 'creates items' do
          expect { subject.run }.to change(Item, :count).by(1)
        end

        it 'sets count of items to 1' do
          subject.run

          Order.all.includes(operations: :item).each do |o|
            o.operations.each { |op| expect(op.item.count).to eq 1 }
          end
        end

        it 'runs :to_stock! method' do
          expect_any_instance_of(Invent::Item).to receive(:to_stock!)
          subject.run
        end

        it 'sets :default priority to each item' do
          subject.run

          Order.all.includes(:inv_items).each do |o|
            o.inv_items.each { |i| expect(i.status).to eq 'in_stock' }
          end
        end

        it 'broadcasts to items' do
          expect_any_instance_of(Orders::In::AbstractState).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to archive_orders' do
          expect_any_instance_of(Orders::In::AbstractState).to receive(:broadcast_archive_orders)
          subject.run
        end

        context 'and when warehouse_item already exist (with another model)' do
          let!(:w_item) { create(:used_item, count: 1, inv_item: inv_item, item_model: '12345') }
          let(:operation) { attributes_for(:order_operation, item_id: w_item.id, shift: -1) }
          let(:execute_order_params) do
            edit = Edit.new(Order.last.id)
            edit.run
            edit.data[:order]['consumer_tn'] = current_user.tn
            edit.data[:order]['operations_attributes'].each do |op|
              op['status'] = 'done'

              op.delete('item')
              op.delete('inv_items')
              op.delete('inv_item_ids')
              op.delete('formatted_date')
              op.delete('invent_num_order')
              op.delete('operations_warehouse_receiver')
            end

            edit.data[:order].delete('consumer_obj')
            edit.data[:order].delete('fio_user_iss')
            edit.data[:order].delete('attachment_order')
            edit.data[:order].delete('type_ops_warehouse_receiver')
            edit.data[:order].delete('valid_op_warehouse_receiver_fio')
            edit.data[:order]
          end
          before do
            order_params = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
            order_params[:operations_attributes] = [operation]
            CreateOut.new(create(:***REMOVED***_user), order_params.as_json).run
            ExecuteOut.new(current_user, Order.last.id, execute_order_params.as_json).run
          end

          its(:run) { is_expected.to be_truthy }
        end
      end

      context 'when operation is :write_off' do
        let(:user) { create(:shatunova_user) }
        let!(:w_item) { create(:used_item, inv_item: inv_item) }
        subject { CreateByInvItem.new(user, inv_item, :write_off) }

        its(:run) { is_expected.to be_truthy }

        it 'creates order' do
          expect { subject.run }.to change(Order, :count).by(1)
        end

        it 'creates warehouse_operation records' do
          expect { subject.run }.to change(Operation, :count).by(1)
        end

        it 'sets :processing to the operation attribute' do
          Operation.all.each { |op| expect(op.processing?).to be_truthy }
        end

        it 'sets :processing to the order status' do
          subject.run

          expect(Order.last.processing?).to be_truthy
        end

        it 'sets count_reserved of item to 1' do
          subject.run

          expect(w_item.reload.count).to eq 1
        end

        it 'does not create inv_item' do
          expect { subject.run }.not_to change(Invent::Item, :count)
        end

        it 'does not create item' do
          expect { subject.run }.not_to change(Item, :count)
        end

        it 'sets :waiting_write_off to the warehouse_item and invent_item' do
          subject.run

          expect(inv_item.reload.status).to eq 'waiting_write_off'
          expect(w_item.reload.status).to eq 'waiting_write_off'
        end

        it 'broadcasts to write_off_orders' do
          expect_any_instance_of(Orders::WriteOff::AbstractState).to receive(:broadcast_write_off_orders)

          subject.run
        end

        it 'broadcasts to items' do
          expect_any_instance_of(Orders::WriteOff::AbstractState).to receive(:broadcast_items)

          subject.run
        end
      end
    end
  end
end
