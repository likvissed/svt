require 'spec_helper'

module Inventory
  module Workplaces
    RSpec.describe Index, type: :model do
      let(:user) { create :user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }
      let(:workplace_count_***REMOVED***) { create :active_workplace_count, division: ***REMOVED***, users: [user] }
      let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      let!(:workplace_***REMOVED***) { create :workplace_mob, :add_items, items: %i[notebook], status: :confirmed, workplace_count: workplace_count_***REMOVED*** }
      before { subject.run }
      
      it 'fills the @data object with %i[workplaces] keys' do
        expect(subject.data).to include(:workplaces)
      end
      
      context 'with init_filters' do
        subject { Index.new(true) }
        
        it 'assigns :divisions to the :filters key' do
          expect(subject.data[:filters][:divisions].first).to eq workplace_count
        end

        its(:run) { is_expected.to be_truthy }
      end
      
      context 'without init_filters and filters' do
        it 'does not create a :filters key' do
          expect(subject.data[:filters]).to be_nil
        end
        
        it 'returns all workplaces data' do
          expect(subject.data[:workplaces].count).to eq Workplace.count
        end

        its(:run) { is_expected.to be_truthy }
      end
      
      context 'with filters' do
        context 'with division filter' do
          let(:filter) do
            { 
              workplace_count_id: workplace_count.workplace_count_id,
              status: 'all'
            }
          end
          subject { Index.new(false, filter.as_json) }
          
          it 'returns filtered data' do
            expect(subject.data[:workplaces].count).to eq 1
            expect(subject.data[:workplaces].first['workplace_count_id']).to eq workplace.workplace_count_id
          end
        end
        
        context 'with status filter' do
          let(:filter) do
            {
              workplace_count_id: 0,
              status: 'confirmed'
            }
          end
          subject { Index.new(false, filter.as_json) }

          it 'returns filtered data' do
            expect(subject.data[:workplaces].count).to eq 1
            expect(subject.data[:workplaces].first['workplace_count_id']).to eq workplace_***REMOVED***.workplace_count_id
          end
        end
      end
      
      it 'fills the workplaces array at least with %w[division responsibles phone date-range waiting ready] keys' do
        expect(subject.data[:workplaces].first)
          .to include('division', 'wp_type', 'responsible', 'location', 'count', 'status')
      end

      it 'must create @workplaces variable' do
        expect(subject.instance_variable_get :@workplaces).not_to be_nil
      end
    end
  end
end