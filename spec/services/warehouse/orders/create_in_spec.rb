require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateIn, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      let(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:operation_1) { attributes_for(:order_operation, inv_item_ids: [workplace_1.items.first.item_id]) }
      let(:operation_2) { attributes_for(:order_operation, inv_item_ids: [workplace_2.items.first.item_id]) }
      let(:operation_3) { attributes_for(:order_operation, item_type: 'Мышь', item_model: 'Logitech') }
      let(:order_params) do
        order = attributes_for(:order)
        # Операции с инв. номером
        order[:operations_attributes] = [operation_1, operation_2]
        # Операции без инв. номера
        order[:operations_attributes] << operation_3
        order
      end
      let(:op_with_inv) { order_params[:operations_attributes].select { |attr| attr[:inv_item_ids] } }
      let(:op_without_inv) { order_params[:operations_attributes].reject { |attr| !attr[:inv_item_ids] } }
      let(:invent_item_ids) { order_params[:operations_attributes].select { |attr| attr[:invent_item_id] }.map { |op| op[:invent_item_id] } }
      subject { CreateIn.new(current_user, order_params.as_json) }

      its(:run) { is_expected.to be_truthy }

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
        expect { subject.run }.to change(Order, :count).by(3)
      end

      it 'sets total count of created orders to the data variable' do
        subject.run
        expect(subject.data).to eq 3
      end

      it 'changes status to :waiting_bring of each selected item' do
        subject.run
        order_params[:operations_attributes].select { |attr| attr[:inv_item_ids] }.each do |op|
          expect(Invent::Item.find(op[:inv_item_ids].first).status).to eq 'waiting_bring'
        end
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
    end
  end
end
