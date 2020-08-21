require 'feature_helper'

module Invent
  module Items
    RSpec.describe ToStock, type: :model do
      let!(:user) { create(:user) }
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:item) { workplace.items.first }
      let(:create_by_inv_item) { Warehouse::Orders::CreateByInvItem.new(user, item, :in) }
      let(:update_location_w_item) { Warehouse::Items::Update.new(user, item.id, w_items_params) }
      let(:new_location) { build(:location) }
      let(:w_items_params) do
        send_to_stock = create_by_inv_item
        send_to_stock.run

        w_item = item.warehouse_item.as_json
        w_item['location_attributes'] = new_location.as_json
        w_item
      end
      subject { ToStock.new(user, item.item_id, new_location) }

      before { allow(Warehouse::Orders::CreateByInvItem).to receive(:new).and_return(create_by_inv_item) }
      before { allow(UnregistrationWorker).to receive(:perform_async).and_return(true) }

      context 'when warehouse_item is empty for item' do
        its(:run) { is_expected.to be_truthy }

        it 'creates Warehouse::Orders::CreateByInvItem instance' do
          expect(Warehouse::Orders::CreateByInvItem).to receive(:new).with(user, item, :in)

          subject.run
        end

        context 'when update_location_w_item receive :new' do
          before { allow(Warehouse::Items::Update).to receive(:new).and_return(update_location_w_item) }

          it 'creates Warehouse::Items::Update instance' do
            expect(create_by_inv_item).to receive(:run).and_return(true)
            expect(Warehouse::Items::Update).to receive(:new).with(user, item.id, w_items_params)

            subject.run
          end

          it 'runs :run methods for Warehouse::Orders::CreateByInvItem and Warehouse::Items::Update instances' do
            expect(create_by_inv_item).to receive(:run).and_return(true)
            expect(update_location_w_item).to receive(:run).and_return(true)

            subject.run
          end
        end

        it 'create new location for warehouse_item' do
          subject.run

          expect(item.warehouse_item.location.site_id).to eq new_location.site_id
          expect(item.warehouse_item.location.building_id).to eq new_location.building_id
          expect(item.warehouse_item.location.room_id).to eq new_location.room_id
        end
      end

      context 'when warehouse_item is present for item' do
        let(:other_location) { create(:other_location) }
        let(:expanded_warehouse_item) { create(:expanded_item, location: other_location) }

        its(:run) { is_expected.to be_truthy }

        before { item.warehouse_item = expanded_warehouse_item }

        it 'update location for warehouse_item' do
          subject.run

          item.warehouse_item.reload
          expect(item.warehouse_item.location.site_id).to eq new_location.site_id
          expect(item.warehouse_item.location.building_id).to eq new_location.building_id
          expect(item.warehouse_item.location.room_id).to eq new_location.room_id
        end
      end
    end
  end
end
