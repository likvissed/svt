require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe EditWorkplace, type: :model do
      let(:user) { create :user }

      context 'when workplace is found' do
        let(:workplace_count) { create :active_workplace_count, users: [user] }
        let!(:workplace) do
          create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
        end
        subject { EditWorkplace.new(user, workplace.workplace_id) }

        include_examples 'run methods', %w[load_workplace]

        context 'when @data is filling' do
          before { subject.run }

          it 'fills @data at least with %w[location_room_name inv_items_attributes] keys' do
            expect(subject.data).to include('location_room_name', 'inv_items_attributes')
          end

          it 'fills each inv_items_attribute at least with %w[id inv_property_values_attributes] keys' do
            subject.data['inv_items_attributes'].each do |item|
              expect(item).to include('id', 'inv_property_values_attributes')
            end
          end

          it 'fills each inv_property_values_attribute at least with "id" key' do
            subject.data['inv_items_attributes'].each do |item|
              item['inv_property_values_attributes'].each do |prop_val|
                expect(prop_val).to include('id')
              end
            end
          end
        end
      end

      context 'when workplace is not found' do
        subject { EditWorkplace.new(user, 0) }

        it 'raises RecordNotFound error' do
          expect { subject.run }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
