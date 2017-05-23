require 'spec_helper'

module Inventory
  RSpec.describe Room, type: :model do
    let(:building) { IssReferenceBuilding.first }

    context 'when room exists' do
      let(:room) { building.iss_reference_rooms.first }
      subject { Room.new(room.name, building.building_id) }

      it 'assigns room object to @data' do
        subject.run
        expect(subject.data).to eq room
      end

      it 'returns true' do
        expect(subject.run).to be_truthy
      end
    end

    context 'when room not exists' do
      subject { Room.new('Testing_name', building.building_id) }

      it 'creates room' do
        expect { subject.run }.to change(building.iss_reference_rooms, :count).by(1)
      end

      it 'assigns room object to @data' do
        subject.run
        expect(subject.data).to eq building.iss_reference_rooms.last
      end

      it 'returns true' do
        expect(subject.run).to be_truthy
      end
    end

    context 'with invalid building_id' do
      subject { Room.new('Testing_name', 999999) }

      it 'returns false' do
        expect(subject.run).to be_falsey
      end

      it 'adds error to @data variable' do
        subject.run
        expect(subject.errors.details[:base]).to include(error: :building_not_found)
      end
    end
  end
end