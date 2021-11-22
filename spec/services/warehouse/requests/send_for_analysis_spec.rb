require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe SendForAnalysis, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let(:request_params) do
        req = attributes_for(:request_category_one)
        req[:status] = 'analysis'
        req
      end

      subject { SendForAnalysis.new(current_user, request.request_id, request_params) }

      it 'updates status for request' do
        subject.run

        expect(request.reload.status).to eq('analysis')
      end
    end
  end
end
