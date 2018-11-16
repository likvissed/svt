require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateIn, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      let(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:workplace_3) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: 712) }
      let(:operation_1) { attributes_for(:order_operation, inv_item_ids: [workplace_1.items.first.item_id]) }
      let(:operation_2) { attributes_for(:order_operation, inv_item_ids: [workplace_2.items.first.item_id]) }
      let(:operation_3) { attributes_for(:order_operation, item_type: 'Мышь', item_model: 'Logitech') }
      let(:operation_4) { attributes_for(:order_operation, inv_item_ids: [workplace_3.items.first.item_id]) }
      let(:order_params) do
        order = attributes_for(:order)
        # Операции с инв. номером
        order[:operations_attributes] = [operation_1, operation_2, operation_4]
        # Операции без инв. номера
        order[:operations_attributes] << operation_3
        order
      end
      let(:op_with_inv) { order_params[:operations_attributes].select { |attr| attr[:inv_item_ids] } }
      let(:op_without_inv) { order_params[:operations_attributes].reject { |attr| !attr[:inv_item_ids] } }
      let(:invent_item_ids) { order_params[:operations_attributes].map { |op| op[:inv_item_ids] }.flatten.compact }
      subject { CreateIn.new(current_user, order_params.as_json) }

      its(:run) { is_expected.to be_truthy }

      context 'when :operation attribute is :out' do
        before { order_params['operation'] = 'out' }

        its(:run) { is_expected.to be_falsey }
      end

      context 'when :shift attribute of any operation has negative value' do
        before { order_params[:operations_attributes].first[:shift] = -4 }

        its(:run) { is_expected.to be_falsey }
      end

      context 'when warehouse_item is not exist' do
        it 'creates warehouse_item record' do
          expect { subject.run }.to change(Item, :count).by(op_with_inv.count)
        end

        let(:order) { Order.first }
        let(:item) { order.items.first }
        let(:inv_item) { workplace_1.items.first }

        it 'sets item data to the corresponding operation and warehouse_item records' do
          subject.run

          expect(order.operations.first.item).to eq item
          expect(item.inv_item).to eq inv_item
        end

        it 'sets "count" attribute to 0 for each created warehouse_item' do
          subject.run
          Item.all.each { |item| expect(item.count).to be_zero }
        end
      end

      context 'when warehouse_item exists' do
        let!(:existing_item) { create(:used_item, inv_item: workplace_1.items.first, item_model: 'qwerty') }

        it 'updates item_model attribute' do
          subject.run

          expect(existing_item.reload.item_model).to eq existing_item.operations.first.item_model
        end

        context 'and when order was not saved' do
          let(:order) { build(:order) }
          before do
            allow(Order).to receive(:new).and_return(order)
            allow(order).to receive(:save).and_return(false)
          end

          it 'does not change warehouse_item' do
            expect(existing_item.reload.item_model).to eq 'qwerty'
          end
        end
      end

      it 'creates warehouse_operations records' do
        expect { subject.run }.to change(Operation, :count).by(order_params[:operations_attributes].size)
      end

      it 'creates warehouse_item_to_orders records' do
        expect { subject.run }.to change(InvItemToOperation, :count).by(op_with_inv.size)
      end

      it 'creates as many warehouse_orders as the number of workplaces is specified in the operations_attributes (plus one more if the operation does not have invent_item_id param)' do
        expect { subject.run }.to change(Order, :count).by(4)
      end

      it 'sets total count of created orders to the data variable' do
        subject.run
        expect(subject.data).to eq 4
      end

      it 'changes status to :waiting_bring of each selected item' do
        subject.run
        order_params[:operations_attributes].select { |attr| attr[:inv_item_ids] }.each do |op|
          expect(Invent::Item.find(op[:inv_item_ids].first).status).to eq 'waiting_bring'
        end
      end

      it 'broadcasts to items' do
        expect(subject).to receive(:broadcast_items)
        subject.run
      end

      it 'broadcasts to in_orders' do
        expect_any_instance_of(AbstractState).to receive(:broadcast_in_orders)
        subject.run
      end

      context 'when order was not created' do
        let(:order) { build(:order) }
        before do
          allow(Order).to receive(:new).and_return(order)
          allow(order).to receive(:save).and_return(false)
        end

        include_examples 'failed creating :in'
      end

      context 'when invent_item was not updated' do
        before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

        include_examples 'failed creating :in'
      end

      context 'and when invent_item did not pass validations' do
        before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) }

        include_examples 'failed creating :in'
      end

      context 'when item did not pass validations' do
        before { allow(Item).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid) }

        include_examples 'failed creating :in'
      end

      context 'and when item was not created' do
        before { allow(Item).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotSaved) }

        include_examples 'failed creating :in'
      end

      context 'when operations is empty' do
        before { order_params[:operations_attributes] = [] }

        its(:run) { is_expected.to be_falsey }

        [Order, Item, InvItemToOperation, Operation].each do |klass|
          it "does not create #{klass.name} model" do
            expect { subject.run }.not_to change(klass, :count)
          end
        end
      end

      context 'when flag :done is set' do
        let(:inv_item_1) { workplace_1.items.first }
        let!(:item) { create(:used_item, inv_item: inv_item_1, count: 0, count_reserved: 0) }
        let(:operation_1) { attributes_for(:order_operation, inv_item_ids: [inv_item_1.item_id]) }
        let(:inv_item_2) { workplace_2.items.first }
        let(:operation_2) { attributes_for(:order_operation, inv_item_ids: [inv_item_2.item_id]) }
        let(:operation_3) { attributes_for(:order_operation, item_type: 'Мышь', item_model: 'Logitech') }
        let(:order_params) do
          order = attributes_for(:order, consumer_fio: current_user.fullname)
          # Операции с инв. номером
          order[:operations_attributes] = [operation_1, operation_2]
          # Операции без инв. номера
          order[:operations_attributes] << operation_3

          order['status'] = 'done'
          order['dont_calculate_status'] = true
          order
        end
        subject { CreateIn.new(current_user, order_params.as_json) }
        before { Invent::Item.update_all(priority: :high) }

        its(:run) { is_expected.to be_truthy }

        it 'sets :done to the each operation attribute' do
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
          expect { subject.run }.to change(Item, :count).by(2)
        end

        it 'sets count of items to 1' do
          subject.run

          Order.all.includes(operations: :item).each do |o|
            o.operations.each do |op|
              expect(op.item.count).to eq 1
            end
          end
        end

        it 'sets count_reserved of items to 0' do
          subject.run

          Order.all.includes(operations: :item).each do |o|
            o.operations.each do |op|
              expect(op.item.count_reserved).to eq 0
            end
          end
        end

        it 'sets nil to the workplace, :in_stock to the status and :default to the priority attributes into the invent_item record' do
          subject.run
          [inv_item_1.reload, inv_item_2.reload].each do |inv_item|
            expect(inv_item.workplace).to be_nil
            expect(inv_item.status).to eq 'in_stock'
            expect(inv_item.priority).to eq 'default'
          end
        end

        it 'does not set nil to the workplace into another invent_item records' do
          subject.run

          Invent::Item.where.not(item_id: [inv_item_1, inv_item_2].map(&:item_id)).each do |inv_item|
            expect(inv_item.workplace).not_to be_nil
          end
        end

        it 'broadcasts to archive_orders' do
          expect_any_instance_of(AbstractState).to receive(:broadcast_archive_orders)
          subject.run
        end
      end
    end
  end
end
