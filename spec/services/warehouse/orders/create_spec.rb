require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Create, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      let(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:operation_1) { attributes_for(:order_operation, invent_item_id: workplace_1.items.first.item_id) }
      let(:operation_2) { attributes_for(:order_operation, invent_item_id: workplace_2.items.first.item_id) }
      let(:operation_3) { attributes_for(:order_operation, item_type: 'Мышь', item_model: 'Logitech')  }

      let(:order_params) do
        order = attributes_for(:order, workplace: nil, consumer_dept: ***REMOVED***)
        # Операции с инв. номером
        order[:operations_attributes] = [operation_1, operation_2]
        # Операции без инв. номера
        order[:operations_attributes] << operation_3
        order
      end
      let(:op_with_inv) { order_params[:operations_attributes].select { |attr| attr[:invent_item_id] } }
      let(:op_without_inv) { order_params[:operations_attributes].reject { |attr| attr[:invent_item_id] } }
      subject { Create.new(current_user, order_params.as_json) }

      its(:run) { is_expected.to be_truthy }

      context 'when warehouse_item does not exist' do
        it 'creates warehouse_item record' do
          expect { subject.run }.to change(Item, :count).by(op_with_inv.count)
        end

        it 'sets "count" attribute to 0 for each created warehouse_item' do
          subject.run
          Item.all.each { |item| expect(item.count).to be_zero }
        end
      end

      it 'creates warehouse_operations records' do
        expect { subject.run }.to change(Operation, :count).by(order_params[:operations_attributes].size)
      end

      it 'creates warehouse_item_to_orders records' do
        expect { subject.run }.to change(ItemToOrder, :count).by(op_with_inv.size)
      end

      it 'creates as many warehouse_orders as the number of workplaces is specified in the operations_attributes (plus one more if the operation does not have invent_item_id param)' do
        expect { subject.run }.to change(Order, :count).by(3)
      end

      it 'changes status to :waiting_bring in the each selected item' do
        subject.run
        order_params[:operations_attributes].select { |attr| attr[:invent_item_id] }.each do |op|
          expect(Invent::Item.find(op[:invent_item_id]).status).to eq 'waiting_bring'
        end
      end

      context 'when invent_item was not updated' do
        let(:order) { build(:order) }
        before do
          allow(Order).to receive(:new).and_return(order)
          allow(order).to receive(:save).and_return(false)
        end
        let(:invent_item_ids) { order_params[:operations_attributes].select { |attr| attr[:invent_item_id] }.map { |op| op[:invent_item_id] } }

        [Order, Item, ItemToOrder, Operation].each do |klass|
          it "does not create #{klass.name} model" do
            expect { subject.run }.not_to change(klass, :count)
          end
        end

        it 'does not change status of Invent::Item model' do
          subject.run
          Invent::Item.where(item_id: invent_item_ids).each { |item| expect(item.status).to be_nil }
        end

        its(:run) { is_expected.to be_falsey }
      end

      context 'when operations is empty' do
        before { order_params[:operations_attributes] = [] }

        its(:run) { is_expected.to be_falsey }

        [Order, Item, ItemToOrder, Operation].each do |klass|
          it "does not create #{klass.name} model" do
            expect { subject.run }.not_to change(klass, :count)
          end
        end
      end
    end
  end
end
