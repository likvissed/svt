require 'spec_helper'

module Invent
  module WorkplaceCounts
    RSpec.describe Show, type: :model do
      let(:***REMOVED***_user) { create(:***REMOVED***_user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
      subject { Show.new(workplace_count.workplace_count_id) }

      include_examples 'run methods', 'load_workplace_count'

      it 'fills the @data with %w[division time_start time_end] keys' do
        subject.run
        expect(subject.data).to include('division', 'time_start', 'time_end', 'users_attributes')
      end
    end
  end
end
