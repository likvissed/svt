require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Create, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let(:order_params) do
        order = attributes_for(:order, workplace: workplace)
        order[:item_to_orders_attributes] = []
        order[:item_to_orders_attributes].push(invent_item_id: workplace.items.first.item_id)
        order[:item_to_orders_attributes].push(invent_item_id: workplace.items.last.item_id)

        order
      end
      subject { Create.new(current_user, order_params) }

      its(:run) { is_expected.to be_truthy }

      context 'when warehouse_item does not exist' do
        it 'creates warehouse_item record' do
          expect { subject.run }.to change(Item, :count).by(order_params[:item_to_orders_attributes].count)
        end

        it 'sets "count" attribute to 0 for each created warehouse_item' do
          subject.run
          Item.all.each { |item| expect(item.count).to be_zero }
        end
      end

      it 'creates warehouse_operations records' do
        expect { subject.run }.to change(Operation, :count).by(order_params[:item_to_orders_attributes].count)
      end

      it 'creates warehouse_item_to_orders records' do
        expect { subject.run }.to change(ItemToOrder, :count).by(order_params[:item_to_orders_attributes].count)
      end

      it 'creates one warehouse_orders record' do
        expect { subject.run }.to change(Order, :count).by(1)
      end

      it 'changes status to :waiting_bring in the each selected item' do
        subject.run
        order_params[:item_to_orders_attributes].each do |item|
          expect(Invent::Item.find(item[:invent_item_id]).status).to eq 'waiting_bring'
        end
      end

      context 'when invent_item was not updated' do
        let(:order) { build(:order) }
        before do
          allow(Order).to receive(:new).and_return(order)
          allow(order).to receive(:save).and_return(false)
        end
        let(:item_ids) { order_params[:item_to_orders_attributes].map { |io| io[:invent_item_id] } }

        [Order, Item, ItemToOrder].each do |klass|
          it "does not create #{klass.name} model" do
            expect { subject.run }.not_to change(klass, :count)
          end
        end

        it 'does not change status of Invent::Item model' do
          subject.run
          Invent::Item.where(item_id: item_ids).each do |item|
            expect(item.status).to be_nil
          end
        end
      end
    end
  end
end
