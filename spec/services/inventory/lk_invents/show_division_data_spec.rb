require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe ShowDivisionData, type: :model do
      let(:workplace_count) { create(:active_workplace_count, user: build(:user)) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end

      subject { ShowDivisionData.new(workplace_count.division) }

      include_examples 'run methods', %w[load_workplace load_users]

      context 'when @data is filling' do
        let!(:data_keys) { %i[workplaces users] }
        before { subject.run }

        it 'fills the @data with %i[workplaces users] keys' do
          expect(subject.data.keys).to include *data_keys
        end

        it 'puts the :workplaces at least with %w[short_description fio duty location status] keys' do
          expect(subject.data[:workplaces].first).to include(
            'short_description', 'fio', 'duty', 'location', 'status'
          )
        end

        it 'puts the :users at least with %w[id_tn fio] keys' do
          expect(subject.data[:users].first.as_json).to include('id_tn', 'fio')
        end
      end
    end
  end
end
