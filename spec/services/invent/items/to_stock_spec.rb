require 'feature_helper'

module Invent
  module Items
    RSpec.describe ToStock, type: :model do
      skip_users_reference

      let(:employee) { build(:emp_***REMOVED***) }
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
      before do
        allow(Warehouse::Orders::CreateByInvItem).to receive(:new).and_return(create_by_inv_item)
        allow(UnregistrationWorker).to receive(:perform_async).and_return(true)

        allow_any_instance_of(Warehouse::Order).to receive(:set_consumer).and_return([employee])
        allow_any_instance_of(Warehouse::Order).to receive(:find_employee_by_workplace).and_return([employee])
      end
      subject { ToStock.new(user, item.item_id, new_location) }

      context 'when warehouse_item is empty for item' do
        its(:run) { is_expected.to be_truthy }

        it 'creates Warehouse::Orders::CreateByInvItem instance' do
          expect(Warehouse::Orders::CreateByInvItem).to receive(:new).with(user, item, :in, nil)

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

        context 'and when assign location for warehouse_item with barcode' do
          let(:item) do
            i_item = build(:item, :with_property_values, type_name: :printer)
            i_item.workplace = workplace
            i_item.save(validate: false)
            i_item
          end
          let(:existing_item) do
            w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
            w_item.build_barcode_item
            w_item.item = item
            w_item.save(validate: false)
            w_item
          end

          before { item.warehouse_items = [existing_item] }

          it 'creates warehouse_location records' do
            expect { subject.run }.to change(Warehouse::Location, :count).by(item.warehouse_items.size + 1)
          end

          it 'deletes invent_property_value records' do
            expect { subject.run }.to change(PropertyValue, :count).by(-1)
          end

          it 'update params for warehouse_item with barcode' do
            subject.run

            expect(existing_item.reload.status).to eq 'used'
            expect(existing_item.reload.count).to eq 1
            expect(existing_item.reload.invent_property_value).to be_nil
          end

          it 'create new location for warehouse_item with barcode' do
            subject.run

            expect(existing_item.reload.location.site_id).to eq new_location.site_id
            expect(existing_item.reload.location.building_id).to eq new_location.building_id
            expect(existing_item.reload.location.room_id).to eq new_location.room_id
          end

          it 'create new location for warehouse_item without barcode' do
            subject.run

            expect(item.reload.warehouse_item.location.site_id).to eq new_location.site_id
            expect(item.reload.warehouse_item.location.building_id).to eq new_location.building_id
            expect(item.reload.warehouse_item.location.room_id).to eq new_location.room_id
          end
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

        context 'and when comment is present' do
          let(:order_comment) { 'comment example' }
          let!(:create_by_inv_item) { Warehouse::Orders::CreateByInvItem.new(user, item, :in, order_comment) }

          it 'adds comment in order' do
            subject.run

            expect(item.warehouse_orders.first.comment).to eq order_comment
          end
        end
      end
    end
  end
end
