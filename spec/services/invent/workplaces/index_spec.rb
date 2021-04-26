require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Index, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let(:workplace_count_***REMOVED***) { create(:active_workplace_count, division: ***REMOVED***, users: [user]) }
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }
      let!(:workplace_***REMOVED***) { create(:workplace_mob, :add_items, items: %i[notebook], status: :confirmed, workplace_count: workplace_count_***REMOVED***) }
      let(:sort) do
        {
          name: :workplace_id,
          type: :desc
        }
      end
      let(:params) do
        {
          draw: 1,
          start: 0,
          length: 25,
          search: { value: '', regex: '' },
          init_filters: false,
          filters: false,
          sort: sort.to_json
        }
      end
      subject { Index.new(user, params) }
      before { subject.run }

      it 'fills the @data object with %i[data recordsTotal recordsFiltered] keys' do
        expect(subject.data).to include(:data, :recordsTotal, :recordsFiltered)
      end

      it 'adds %w[location responsible label_status] fields to the data' do
        expect(subject.data[:data].first).to include('location', 'responsible', 'label_status')
      end

      context 'with init_filters' do
        subject do
          params[:init_filters] = 'true'
          Index.new(user, params)
        end

        it 'assigns %i[divisions statuses types buildings] to the :filters key' do
          expect(subject.data[:filters]).to include(:divisions, :statuses, :types, :buildings)
        end

        it 'loads site for corresponding room' do
          expect(subject.data[:filters][:buildings].first[:site_name]).to eq IssReferenceBuilding.first.iss_reference_site.name
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'without init_filters and filters' do
        it 'does not create a :filters key' do
          expect(subject.data[:filters]).to be_nil
        end

        it 'returns all workplaces data' do
          expect(subject.data[:data].count).to eq Workplace.count
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'with filters' do
        let(:filter) { {} }
        subject do
          params[:filters] = filter
          Index.new(user, params)
        end

        context 'and with :fullname filter' do
          let(:filter) { { fullname: workplace.user_iss.fio }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace.workplace_count_id
          end
        end

        context 'and with :invent_num filter' do
          let(:filter) { { invent_num: workplace.items.first.invent_num }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace.workplace_count_id
          end
        end

        context 'and with :workplace_id fitler' do
          let(:filter) { { workplace_id: workplace.workplace_id }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace.workplace_count_id
          end
        end

        context 'and with :workplace_count_id filter' do
          let(:filter) { { workplace_count_id: workplace_count.workplace_count_id }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace.workplace_count_id
          end
        end

        context 'and with :status filter' do
          let(:filter) { { status: 'confirmed' }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace_***REMOVED***.workplace_count_id
          end
        end

        context 'and with :workplace_type_id filter' do
          let(:filter) { { workplace_type_id: workplace.workplace_type_id }.to_json }

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_type_id']).to eq workplace.workplace_type_id
          end
        end

        context 'and with :location_building_id filter' do
          let(:filter) { { location_building_id: workplace.location_building_id }.to_json }

          it 'returns filtered data' do
            subject.data[:data].each do |el|
              expect(el['location_building_id']).to eq workplace.location_building_id
            end
          end
        end

        context 'and with :location_room_id filter' do
          let(:filter) { { location_room_id: workplace.location_room_id }.to_json }

          it 'returns filtered data' do
            subject.data[:data].each do |el|
              expect(el['location_room_id']).to eq workplace.location_room_id
            end
          end
        end
      end

      it 'loads the number of records specified in params[:length]' do
        expect(subject.data[:data].length).to be <= params[:length]
      end

      it 'fills the workplaces array at least with %w[division responsibles phone date-range waiting ready] keys' do
        expect(subject.data[:data].first)
          .to include('division', 'wp_type', 'responsible', 'location', 'count_items', 'count_attachments', 'status')
      end

      it 'must create @workplaces variable' do
        expect(subject.instance_variable_get(:@workplaces)).not_to be_nil
      end

      context 'when responsible user was dismissed' do
        let(:dismissed_user) { build(:invalid_user) }
        let!(:workplace) do
          w = build(
            :workplace_pk,
            :add_items,
            items: %i[pc monitor],
            workplace_count: workplace_count,
            id_tn: dismissed_user.id_tn
          )

          w.save(validate: false)
          w
        end

        it 'must add "Ответственный не найден" to the responsible field' do
          expect(subject.data[:data].last['responsible']).to match 'Ответственный не найден'
        end
      end
    end
  end
end
