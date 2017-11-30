require 'spec_helper'

module Invent
  module WorkplaceCounts
    RSpec.describe Index, type: :model do
      let!(:workplace_count) { create(:active_workplace_count, users: [create(:user)]) }
      let!(:workplaces_ready) do
        create_list(
          :workplace_mob,
          5,
          :add_items,
          items: %i[notebook],
          status: :confirmed,
          workplace_count: workplace_count
        )
      end
      let!(:workplaces_waiting) do
        create_list(
          :workplace_mob,
          3,
          :add_items,
          items: %i[notebook],
          status: :pending_verification,
          workplace_count: workplace_count
        )
      end
      before { subject.run }

      it 'fills the @data array at least with %w[division responsibles phone date-range waiting ready] keys' do
        expect(subject.data.first).to include(
          'division', 'responsibles', 'phones', 'date-range', 'waiting', 'ready'
        )
      end

      it 'must create @workplace_counts variable' do
        expect(subject.instance_variable_get(:@workplace_counts)).not_to be_nil
      end

      it 'sets count of :confirmed workplaces in the "ready" variables' do
        expect(subject.data.first['ready']).to eq workplaces_ready.count
      end

      it 'sets count of :pending_verification workplaces in the "waiting" variables' do
        expect(subject.data.first['waiting']).to eq workplaces_waiting.count
      end
    end
  end
end
