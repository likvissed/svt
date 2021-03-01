require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Update, type: :model do
      let!(:user) { create(:user) }
      let!(:old_workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }

      context 'with valid workplace params' do
        let(:room) { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.last }
        let(:user_iss) { build(:***REMOVED***_user_iss) }
        let(:new_workplace) do
          update_workplace_attributes(true, user, old_workplace.workplace_id, room: room, user_iss: user_iss)
        end
        subject { Update.new(user, old_workplace.workplace_id, new_workplace) }

        it 'creates a @workplace variable' do
          subject.run
          expect(subject.instance_variable_get(:@workplace)).to eq old_workplace
        end

        it 'sets location_room_id variable' do
          subject.run
          expect(subject.instance_variable_get(:@workplace_params)['location_room_id']).to eq room.room_id
        end

        it 'changes workplace attributes' do
          subject.run
          old_workplace.reload
          expect(old_workplace.iss_reference_room).to eq room
          expect(old_workplace.id_tn).to eq user_iss.id_tn
        end

        it 'changes items count' do
          expect { subject.run }.to change(old_workplace.reload.items, :count).by(new_workplace['items_attributes'].count - old_workplace.items.count)
        end

        it 'fills the @data at least with %w[short_description fio duty location status] keys' do
          subject.run
          expect(subject.data).to include('short_description', 'fio', 'duty', 'location', 'status')
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

        it 'broadcasts to archive_orders' do
          expect(subject).not_to receive(:broadcast_archive_orders)
          subject.run
        end

        context 'and when have item with properties assign barcode' do
          before do
            new_workplace['items_attributes'].push(new_item)
            new_workplace['disabled_filters'] = true
          end

          include_examples 'property_value is creating'
        end

        it 'count barcode increased' do
          subject.run

          expect(Barcode.count).to eq new_workplace['items_attributes'].count
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'when add item from another workplace' do
        let!(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
        let(:room) { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.last }
        let(:user_iss) { build(:***REMOVED***_user_iss) }
        let(:new_workplace) do
          wp = Invent::LkInvents::EditWorkplace.new(user, old_workplace.workplace_id)
          wp.run

          wp.data['location_room_name'] = room.name
          wp.data['id_tn'] = user_iss.id_tn

          new_mon = workplace_2.items.last.as_json(include: :property_values)
          new_mon['status'] = 'prepared_to_swap'
          new_mon['id'] = new_mon['item_id']
          new_mon['property_values_attributes'] = new_mon['property_values']
          new_mon['barcode_item_attributes'] = new_mon['barcode_item']
          new_mon['property_values_attributes'].each do |prop_val|
            prop_val['id'] = prop_val['property_value_id']

            prop_val.delete('property_value_id')
          end

          new_mon.delete('item_id')
          new_mon.delete('property_values')
          new_mon.delete('barcode_item')

          wp.data.delete('location_room')
          wp.data['items_attributes'] << new_mon
          wp.data
        end
        let(:swap) { Warehouse::Orders::Swap.new(user, old_workplace.workplace_id, [new_workplace['items_attributes'].last['id']]) }
        subject { Update.new(user, old_workplace.workplace_id, new_workplace) }

        it 'runs Warehouse::Orders::Swap service' do
          expect(Warehouse::Orders::Swap).to receive(:new).with(user, old_workplace.workplace_id, [new_workplace['items_attributes'].last['id']]).and_return(swap)
          expect(swap).to receive(:run)
          subject.run
        end

        it 'increases count of items for current workplace' do
          expect { subject.run }.to change(old_workplace.reload.items, :count).by(1)
        end

        it 'reduces count of items for workplace_2' do
          expect { subject.run }.to change(workplace_2.reload.items, :count).by(-1)
        end

        it 'broadcasts to archive_orders' do
          expect(subject).to receive(:broadcast_archive_orders)
          subject.run
        end

        context 'when Warehouse::Orders::Swap service returns false' do
          before { allow_any_instance_of(Warehouse::Orders::Swap).to receive(:run).and_return(false) }

          its(:run) { is_expected.to be_falsey }

          it 'does not update workplace' do
            subject.run
            old_workplace.reload
            expect(old_workplace.iss_reference_room).not_to eq room
            expect(old_workplace.id_tn).not_to eq user_iss.id_tn
          end
        end
      end

      context 'with invalid workplace params' do
        let(:new_workplace) do
          update_workplace_attributes(false, user, old_workplace.workplace_id)
        end
        subject { Update.new(user, old_workplace.workplace_id, new_workplace) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
