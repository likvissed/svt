require 'spec_helper'

module Inventory
  module WorkplaceCounts
    RSpec.describe Index, type: :model do
      let!(:workplace_count) { create(:active_workplace_count, user: create(:user)) }

      it 'fills the @data array at least with %w[division responsibles phone date-range waiting ready] keys' do
        subject.run
        expect(subject.data.first).to include(
          'division', 'responsibles', 'phones', 'date-range', 'waiting', 'ready'
        )
      end
    end
  end
end
