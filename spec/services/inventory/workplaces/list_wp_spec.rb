require 'spec_helper'

module Inventory
  module Workplaces
    RSpec.describe ListWp, type: :model do
      let(:user) { create :user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }
      let(:workplace_count_***REMOVED***) { create :active_workplace_count, division: ***REMOVED***, users: [user] }
      let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      let!(:workplace_***REMOVED***) { create :workplace_mob, :add_items, items: %i[notebook], status: :confirmed, workplace_count: workplace_count_***REMOVED*** }
      before { subject.run }

      it 'fills the @data object with %i[workplaces] keys' do
        expect(subject.data).to include(:workplaces)
      end

      it 'fills the workplaces array with %i[workplace_id workplace items] keys' do
        expect(subject.data[:workplaces].first)
          .to include(:workplace_id, :workplace, :items)
      end
      
      it 'fills the workplaces array only with workplaces which have the :pending_verification status' do
        expect(subject.data[:workplaces].count).to eq 1
        expect(subject.data[:workplaces].first[:workplace_id]).to eq workplace.workplace_id
      end

      it 'must create @workplaces variable' do
        expect(subject.instance_variable_get :@workplaces).not_to be_nil
      end

      context 'with init_filters' do
        subject { ListWp.new(true) }

        it 'assigns %i[divisions] to the :filters key' do
          expect(subject.data[:filters]).to include(:divisions)
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'with filters' do
        context 'with division filter' do
          let(:filter) { { workplace_count_id: workplace_count.workplace_count_id } }
          subject { ListWp.new(false, filter.as_json) }

          it 'returns filtered data' do
            expect(subject.data[:workplaces].count).to eq 1
            expect(subject.data[:workplaces].first[:workplace]).to match /Отдел: #{workplace.workplace_count.division}/
          end
        end
      end
    end
  end
end
