require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe ShowDivisionData, type: :model do
      let(:workplace_count) { create(:active_workplace_count, user: build(:user)) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end

      subject { ShowDivisionData.new(workplace_count.division) }

      %w[load_workplace load_users].each do |method|
        it "runs #{method} method" do
          expect(subject).to receive(method.to_sym)
          subject.run
        end
      end

      context 'when @data is filling' do
        let!(:data_keys) { %i[workplaces users] }
        before { subject.run }

        it 'fills the @data with %i[workplaces users] keys' do
          expect(subject.data.keys).to include *data_keys
        end

        it 'puts the :workplaces at least with %w[status location fio user_tn duty] keys' do
          expect(subject.data[:workplaces].first).to include('status', 'location', 'fio', 'user_tn', 'duty')
        end

        it 'puts the :users at least with %w[id_tn fio] keys' do
          expect(subject.data[:users].first.as_json).to include('id_tn', 'fio')
        end
      end
    end
  end
end
