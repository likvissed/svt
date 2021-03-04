require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Split, type: :model do
      describe '#run' do
        let(:current_user) { create(:user) }
        let(:item) { create(:item_with_property_values, status: 'non_used', count: 4, invent_num_end: 114) }
        let(:location) { create(:location) }
        let(:items_attributes) do
          edit = Edit.new(current_user, item.id)
          edit.run

          edit.data[:item]['location'] = location.as_json
          edit.data[:item]['count_for_invent_num'] = 2

          items = [edit.data[:item], edit.data[:item]]
          items
        end

        let(:location_for_item_1) { Location.find(Item.first.location_id) }
        let(:location_for_item_2) { Location.find(Item.last.location_id) }

        subject { Split.new(current_user, item.id, items_attributes) }

        context 'when location for present item is blank' do
          before { location.id = '' }

          its(:run) { is_expected.to be_truthy }

          include_examples 'update :invent_num_start and :invent_num_end for items'
          include_examples 'update :count for items'

          it 'the number of items in stock increases' do
            subject.run

            expect(Item.count).to eq items_attributes.count
          end

          it 'change count to location' do
            expect { subject.run }.to change { Location.count }.by(items_attributes.count)
          end

          it 'create new location for items' do
            subject.run

            %i[site_id building_id room_id comment].each do |key|
              expect(location_for_item_1[key.to_s]).to eq location[key.to_s]
              expect(location_for_item_2[key.to_s]).to eq location[key.to_s]
            end
          end

          it 'create property_values for new item' do
            subject.run

            Item.first.property_values.each_with_index do |prop_val, index|
              %i[property_id value].each do |key|
                expect(prop_val[key]).to eq Item.last.property_values[index][key]
              end
            end
          end

          context 'and when present supply for item' do
            let(:supply) { create(:supply) }
            let(:operation) { create(:supply_operation, operationable: supply) }
            before { item.operations = [operation] }

            it 'increase count to operations' do
              expect { subject.run }.to change(Operation, :count).by(1)
            end

            it 'create new operation for item' do
              subject.run

              %i[item_type item_model].each do |key|
                expect(Item.first.operations.first[key.to_s]).to eq item[key.to_s]
              end

              expect(Item.first.operations.first['item_id']).to eq item.id
              expect(Item.first.operations.first['shift']).to eq items_attributes.first['count_for_invent_num']
            end
          end

          context 'and when room_id is null' do
            before { items_attributes.first['location']['room_id'] = nil }

            include_examples 'items_attributes is invalid'
          end
        end

        context 'when location and property_values for item is present' do
          let(:item) { create(:item_with_property_values, status: 'non_used', count: 5, invent_num_end: 115, location: location) }
          let!(:items_attributes) do
            edit1 = Edit.new(current_user, item.id)
            edit1.run

            edit2 = Edit.new(current_user, item.id)
            edit2.run

            edit1.data[:item]['location'] = location.as_json
            edit1.data[:item]['location_id'] = location.id
            edit1.data[:item]['count_for_invent_num'] = 2

            edit2.data[:item]['location'] = location.as_json
            edit2.data[:item]['location_id'] = 0
            edit2.data[:item]['location']['id'] = ''
            edit2.data[:item]['count_for_invent_num'] = 3

            items = [edit1.data[:item], edit2.data[:item]]
            items
          end

          include_examples 'update :invent_num_start and :invent_num_end for items'
          include_examples 'update :count for items'

          it 'change count to location' do
            expect { subject.run }.to change { Location.count }.by(1)
          end

          it 'create new location for new item' do
            subject.run

            %i[site_id building_id room_id comment].each do |key|
              expect(location_for_item_2[key.to_s]).to eq location[key.to_s]
            end
          end

          context 'and when room_id is null' do
            before { items_attributes.first['location']['room_id'] = nil }

            include_examples 'items_attributes is invalid'
          end
        end
      end
    end
  end
end
