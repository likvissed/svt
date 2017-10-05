require 'spec_helper'

module Invent
  module Workplaces
    RSpec.describe Index, type: :model do
      let(:user) { create :user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }
      let(:workplace_count_***REMOVED***) { create :active_workplace_count, division: ***REMOVED***, users: [user] }
      let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      let!(:workplace_***REMOVED***) { create :workplace_mob, :add_items, items: %i[notebook], status: :confirmed, workplace_count: workplace_count_***REMOVED*** }
      let(:params) do
        {
          draw: 1,
          start: 0,
          length: 25,
          search: { value: '', regex: '' },
          init_filters: false,
          filters: false
        }
      end
      subject { Index.new(params) }
      before { subject.run }

      it 'fills the @data object with %i[data draw recordsTotal recordsFiltered] keys' do
        expect(subject.data).to include(:data, :draw, :recordsTotal, :recordsFiltered)
      end

      context 'with init_filters' do
        subject do
          params[:init_filters] = true
          Index.new(params)
        end

        it 'assigns %i[divisions statuses types] to the :filters key' do
          expect(subject.data[:filters]).to include(:divisions, :statuses, :types)
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
        context 'with division filter' do
          let(:filter) do
            {
              workplace_count_id: workplace_count.workplace_count_id,
              status: 'all',
              workplace_type_id: 0
            }
          end
          subject do
            params[:filters] = filter.as_json
            Index.new(params)
          end

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace.workplace_count_id
          end
        end

        context 'with status filter' do
          let(:filter) do
            {
              workplace_count_id: 0,
              status: 'confirmed',
              workplace_type_id: 0
            }
          end
          subject do
            params[:filters] = filter.as_json
            Index.new(params)
          end

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_count_id']).to eq workplace_***REMOVED***.workplace_count_id
          end
        end

        context 'with type filter' do
          let(:filter) do
            {
              workplace_count_id: 0,
              status: 'all',
              workplace_type_id: workplace.workplace_type_id
            }
          end
          subject do
            params[:filters] = filter.as_json
            Index.new(params)
          end

          it 'returns filtered data' do
            expect(subject.data[:data].count).to eq 1
            expect(subject.data[:data].first['workplace_type_id']).to eq workplace.workplace_type_id
          end
        end
      end

      it 'fills the workplaces array at least with %w[division responsibles phone date-range waiting ready] keys' do
        expect(subject.data[:data].first)
          .to include('division', 'wp_type', 'responsible', 'location', 'count', 'status')
      end

      it 'must create @workplaces variable' do
        expect(subject.instance_variable_get :@workplaces).not_to be_nil
      end

      context 'when responsible user was dismissed' do
        let(:dismissed_user) { build :invalid_user }
        let!(:workplace) do
          w = build :workplace_pk,
                    :add_items,
                    items: %i[pc monitor],
                    workplace_count: workplace_count,
                    id_tn: dismissed_user.id_tn

          w.save(validate: false)
          w
        end

        it 'must add "Ответственный не найден" to the responsible field' do
          expect(subject.data[:data].first['responsible']).to match 'Ответственный не найден'
        end
      end
    end
  end
end