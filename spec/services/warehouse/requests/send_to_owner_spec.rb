require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe SendToOwner, type: :model do
      skip_users_reference
      let(:response_from_ssd) do
        {
          gost_hash: 'dbf48fcbb3a265fb77ac6d',
          process_id: '02e23b1e-4b6a-1',
          definition_id: 'zayav_vt_713:1:92'
        }.stringify_keys
      end
      before do
        allow(Orbita).to receive(:add_event)
        allow(SSD).to receive(:send_for_signature).and_return(response_from_ssd)

        allow_any_instance_of(Order).to receive(:present_user_iss)
        allow_any_instance_of(SendToOwner).to receive(:generate_report)
        allow_any_instance_of(SendToOwner).to receive(:send_into_***REMOVED***)
        allow_any_instance_of(SendToOwner).to receive(:find_login)
      end

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, operation: :out, request: request)
        ord.save(validate: false)
        ord
      end
      let(:owner) { build(:emp_***REMOVED***) }

      subject { SendToOwner.new(current_user, request.request_id, owner) }

      it 'updates status for request' do
        subject.run

        expect(request.reload.status).to eq('on_signature')
      end

      it 'updates data from ssd for request' do
        subject.run

        request.reload
        expect(request.ssd_id).to eq(response_from_ssd['process_id'])
        expect(request.ssd_definition).to eq(response_from_ssd['definition_id'])
      end
    end
  end
end
