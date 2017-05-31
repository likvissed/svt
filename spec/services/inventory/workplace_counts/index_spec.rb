require 'spec_helper'

module Inventory
  module WorkplaceCounts
    RSpec.describe Index, type: :model do
      let!(:workplace_count) { create(:active_workplace_count, users: [create(:user)]) }

      it 'fills the @data array at least with %w[division responsibles phone date-range waiting ready] keys' do
        subject.run
        expect(subject.data.first).to include(
          'division', 'responsibles', 'phones', 'date-range', 'waiting', 'ready'
        )
      end

      it 'must create @workplace_counts variable' do
        subject.run
        expect(subject.instance_variable_get :@workplace_counts).not_to be_nil
      end
    end
  end
end
