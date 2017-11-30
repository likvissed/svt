require 'spec_helper'

module Invent
  module Workplaces
    RSpec.describe Create, type: :model do
      let(:user) { create(:user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
      subject { Create.new(user, workplace) }

      context 'with valid workplace params' do
        let(:room) { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.first }
        let(:workplace) { create_workplace_attributes(true, room: room) }
        let(:prop_val_count) do
          count = 0
          workplace['items_attributes'].each { |item| count += item['property_values_attributes'].count }
          count
        end

        it 'sets location_room_id variable' do
          subject.run
          expect(subject.workplace_params['location_room_id']).to eq room.room_id
        end

        it 'creates a @workplace variable' do
          subject.run
          expect(subject.workplace).to be_an_instance_of Workplace
        end

        it 'saves a new workplace in the database' do
          expect { subject.run }.to change(Workplace, :count).by(1)
        end

        it 'saves a new items in the database' do
          expect { subject.run }.to change(Item, :count).by(workplace['items_attributes'].count)
        end

        it 'saves a new property_values in the database' do
          expect { subject.run }.to change(PropertyValue, :count).by(prop_val_count)
        end

        it 'fills a @data at least with %w[short_description fio duty location status] keys' do
          subject.run
          expect(subject.data).to include('short_description', 'fio', 'duty', 'location', 'status')
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'with invalid workplace params' do
        let(:workplace) { create_workplace_attributes(false) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
