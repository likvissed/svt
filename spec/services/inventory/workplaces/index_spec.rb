require 'spec_helper'

module Inventory
  module Workplaces
    RSpec.describe Index, type: :model do
      let(:workplace_count) { create(:active_workplace_count, users: [create(:user)]) }
      let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }

      it 'fills the @data object with %i[workplaces] keys' do
        subject.run
        expect(subject.data).to include(:workplaces)
      end
      
      context 'with init_filters' do
        subject { Index.new(true) }
        
        it 'assigns :divisions to the :filters key' do
          subject.run
          expect(subject.data[:filters][:divisions].first).to eq workplace_count
        end

        its(:run) { is_expected.to be_truthy }
      end
      
      context 'without init_filters' do
        it 'assigns nil to the :filters key' do
          subject.run
          expect(subject.data[:filters]).to be_nil
        end

        its(:run) { is_expected.to be_truthy }
      end
      
      it 'fills the workplaces array at least with %w[division responsibles phone date-range waiting ready] keys' do
        subject.run
        expect(subject.data[:workplaces].first)
          .to include('division', 'wp_type', 'responsible', 'location', 'count', 'status')
      end

      it 'must create @workplaces variable' do
        subject.run
        expect(subject.instance_variable_get :@workplaces).not_to be_nil
      end
    end
  end
end