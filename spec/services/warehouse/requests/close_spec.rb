require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe Close, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, operation: :out, request: request)
        ord.save(validate: false)
        ord
      end

      subject { Close.new(current_user, request.request_id) }

      it 'updates status for request' do
        subject.run

        expect(request.reload.status).to eq('closed')
      end

      it 'destroys order' do
        expect { subject.run }.to change(Order, :count).by(-1)
      end
    end
  end
end
