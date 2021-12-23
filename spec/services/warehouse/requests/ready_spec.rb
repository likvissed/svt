require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe Ready, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }

      subject { Ready.new(current_user, request.request_id) }

      it 'updates status for request' do
        subject.run

        expect(request.reload.status).to eq('ready')
      end
    end
  end
end
