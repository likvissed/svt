require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Update, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:old_workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end

      context 'with valid workplace params' do
        let(:room) { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.first }
        let(:user_iss) { build(:***REMOVED***_user_iss) }
        let(:new_workplace) do
          update_workplace_attributes(true, user, old_workplace.workplace_id, room: room, user_iss: user_iss)
        end
        subject { Update.new(user, old_workplace.workplace_id, new_workplace) }

        it 'creates a @workplace variable' do
          subject.run
          expect(subject.workplace).to eq old_workplace
        end

        it 'sets location_room_id variable' do
          subject.run
          expect(subject.workplace_params['location_room_id']).to eq room.room_id
        end

        it 'changes workplace attributes' do
          subject.run
          old_workplace.reload
          expect(old_workplace.iss_reference_room).to eq room
          expect(old_workplace.id_tn).to eq user_iss.id_tn
        end

        # FIXME: Спека не проходит
        # it 'changes items count' do
        #   expect { subject.run }.to change(old_workplace.items, :count).by(new_workplace['items_attributes'].count - old_workplace.items.count)
        # end

        it 'fills the @data at least with %w[short_description fio duty location status] keys' do
          subject.run
          expect(subject.data).to include('short_description', 'fio', 'duty', 'location', 'status')
        end

        its(:run) { is_expected.to be_truthy }
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
