require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Destroy, type: :model do
      let!(:user) { create(:user) }
      subject { Destroy.new(user, order.id) }

      context 'when operation is :in' do
        let(:item_1) { create(:item, :with_property_values, type_name: :pc, status: :waiting_bring) }
        let(:item_2) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_bring) }
        let(:workplace) do
          w = build(:workplace_pk, items: [item_1, item_2])
          w.save(validate: false)
          w
        end
        let(:operations) do
          workplace.items.map { |item| build(:order_operation, inv_item_ids: [item.item_id]) }
        end
        let!(:order) { create(:order, inv_workplace: workplace, operations: operations) }

        include_examples 'destroys order with nested models'

        it 'sets nil status to the each inv_item' do
          subject.run
          Invent::Item.find_each do |inv_item|
            expect(inv_item.status).to eq 'in_workplace'
          end
        end

        it 'does not destroy items' do
          expect { subject.run }.not_to change(Item, :count)
        end

        it 'broadcasts to in_orders' do
          expect(subject).to receive(:broadcast_in_orders)
          subject.run
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to workplaces' do
          expect(subject).to receive(:broadcast_workplaces)
          subject.run
        end

        it 'broadcasts to workplaces_list' do
          expect(subject).to receive(:broadcast_workplaces_list)
          subject.run
        end

        context 'and when order is not destroyed' do
          before { allow_any_instance_of(Order).to receive(:destroy).and_return(false) }

          it 'does not change inv_item status' do
            subject.run
            Invent::Item.find_each do |inv_item|
              expect(inv_item.status).to eq 'waiting_bring'
            end
          end

          it 'does not destroy operations' do
            expect { subject.run }.not_to change(Operation, :count)
          end

          its(:run) { is_expected.to be_falsey }
        end
      end

      context 'when operation is :out' do
        context 'and when invent_item already used' do
          let(:inv_item_1) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take) }
          let(:inv_item_2) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_take) }
          let(:inv_item_3) { create(:item, :with_property_values, type_name: :monitor, status: :in_workplace) }
          let(:item_1) { create(:used_item, inv_item: inv_item_1, count_reserved: 1) }
          let(:item_2) { create(:used_item, inv_item: inv_item_2, count_reserved: 1) }
          let(:workplace) do
            w = build(:workplace_pk, items: [inv_item_1, inv_item_2, inv_item_3])
            w.save(validate: false)
            w
          end
          let(:operations) do
            [
              build(:order_operation, item: item_1, inv_item_ids: [inv_item_1.item_id], shift: -1),
              build(:order_operation, item: item_2, inv_item_ids: [inv_item_2.item_id], shift: -1)
            ]
          end
          let!(:order) { create(:order, operation: :out, inv_workplace: workplace, operations: operations) }

          it 'does not remove any inv_items' do
            expect { subject.run }.not_to change(Invent::Item, :count)
          end

          it 'changes status of each inv_item, which belongs to order, to :in_stock' do
            subject.run
            [inv_item_1, inv_item_2].each do |inv_item|
              expect(inv_item.reload.status).to eq 'in_stock'
            end

            expect(inv_item_3.status).to eq 'in_workplace'
          end
        end

        context 'and when invent_item is new' do
          let(:inv_item_1) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take) }
          let(:inv_item_2) { create(:item, :with_property_values, type_name: :monitor, status: :waiting_take) }
          let(:inv_item_3) { create(:item, :with_property_values, type_name: :monitor, status: nil) }
          let(:item_1) { create(:new_item, inv_type: inv_item_1.type, inv_model: nil, item_model: 'Unit', count: 10, count_reserved: 1) }
          let(:item_2) { create(:new_item, inv_type: inv_item_2.type, inv_model: inv_item_2.model, count: 8, count_reserved: 1) }
          let(:workplace) do
            w = build(:workplace_pk, items: [inv_item_1, inv_item_2, inv_item_3])
            w.save(validate: false)
            w
          end
          let(:operations) do
            [
              build(:order_operation, item: item_1, inv_item_ids: [inv_item_1.item_id], shift: -1),
              build(:order_operation, item: item_2, inv_item_ids: [inv_item_2.item_id], shift: -1)
            ]
          end
          let!(:order) { create(:order, operation: :out, inv_workplace: workplace, operations: operations) }

          it 'removes inv_items with :waiting_receive status' do
            expect { subject.run }.to change(Invent::Item, :count).by(-2)
          end

          include_examples 'destroys order with nested models'

          it 'change :count_reserved attribute of Item model' do
            subject.run
            expect(item_1.reload.count_reserved).to be_zero
            expect(item_2.reload.count_reserved).to be_zero
          end

          it 'broadcasts to items' do
            expect(subject).to receive(:broadcast_items).with(order.id)
            subject.run
          end

          it 'broadcasts to out_orders' do
            expect(subject).to receive(:broadcast_out_orders)
            subject.run
          end

          it 'broadcasts to workplaces' do
            expect(subject).to receive(:broadcast_workplaces)
            subject.run
          end

          it 'broadcasts to workplaces_list' do
            expect(subject).to receive(:broadcast_workplaces_list)
            subject.run
          end

          context 'and when order is not destroyed' do
            before { allow_any_instance_of(Order).to receive(:destroy).and_return(false) }

            include_examples 'failed destroy :out order'
          end

          context 'and when inv_item is not destroyed' do
            before { allow_any_instance_of(Invent::Item).to receive(:destroy).and_return(false) }

            include_examples 'failed destroy :out order'
          end

          context 'and when item is not updated' do
            before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed destroy :out order'
          end
        end
      end
    end
  end
end
