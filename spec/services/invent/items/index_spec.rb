require 'feature_helper'

module Invent
  module Items
    RSpec.describe Index, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }
      let!(:sec_workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count, id_tn: ***REMOVED***) }
      let(:item) { workplace.items.first }
      let(:data_keys) { %i[recordsTotal recordsFiltered data] }
      let(:params) { { start: 0, length: 25 } }
      subject { Index.new(params) }

      it 'fills the @data hash with %i[totalRecords data] keys' do
        subject.run
        expect(subject.data.keys).to include(*data_keys)
      end

      it 'adds %w[model description translated_status label_status] field to each item' do
        subject.run
        expect(subject.data[:data].first).to include('model', 'description', 'translated_status', 'label_status')
      end

      context 'with init_filters' do
        before { params[:init_filters] = 'true' }

        it 'assigns %i[types properties statuses] to the :filters key' do
          subject.run
          expect(subject.data[:filters]).to include(:types, :properties, :statuses)
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'without init_filters and filters' do
        it 'does not create a :filters key' do
          expect(subject.data[:filters]).to be_nil
        end

        it 'loads all items' do
          subject.run
          expect(subject.data[:data].count).to eq Item.count
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'with filters' do
        before do
          params[:filters] = filters.as_json
          subject.run
        end

        context 'and with item_id filter' do
          let(:filters) { { item_id: item.item_id } }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['item_id']).to eq item.item_id
          end
        end

        context 'and with type_id filter' do
          let(:filters) { { type_id: item.type_id } }

          it 'returns filtered data' do
            # expect(subject.data[:data].count).to eq 1
            subject.data[:data].each do |el|
              expect(el['type_id']).to eq item.type_id
            end
          end
        end

        context 'and with invent_num filter' do
          let(:filters) { { invent_num: item.invent_num } }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['invent_num']).to eq item.invent_num
          end
        end

        context 'and with responsible filter' do
          let(:filters) { { responsible: workplace.user_iss.fio } }

          it 'returns filtered data' do
            subject.data[:data].each do |el|
              expect(el['workplace']['user_iss']['fio']).to eq workplace.user_iss.fio
            end
          end
        end

        context 'and with property_value filter' do
          let(:prop) { Property.find_by(name: :hdd) }
          let(:filters) do
            {
              properties: [
                {
                  property_id: prop.property_id,
                  property_value: 'String value',
                  exact: true
                }
              ]
            }
          end

          it 'returns filtered data' do
            subject.data[:data].each do |el|
              expect(el['description']).to match(/#{prop.short_description}: #{filters[:properties].first[:property_value]}/)
            end
          end
        end

        context 'and with status filter' do
          let(:status) { :waiting_take }
          let(:status_translated) { Invent::Item.translate_enum(:status, :waiting_take) }
          let(:filters) { { status: status } }
          let!(:item) { create(:item, :with_property_values, type_name: :monitor, status: status) }

          it 'returns filtered data' do
            subject.data[:data].each do |el|
              expect(el['translated_status']).to match(/#{status_translated}/)
            end
          end
        end
      end
    end
  end
end
