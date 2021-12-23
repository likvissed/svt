require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe SendForConfirm, type: :model do
      skip_users_reference
      before do
        allow(Orbita).to receive(:add_event)
        allow_any_instance_of(Order).to receive(:present_user_iss)
      end

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, operation: :out, request: request)
        ord.save(validate: false)
        ord
      end

      subject { SendForConfirm.new(current_user, request.request_id, order.id) }

      it 'updates status for request' do
        subject.run

        expect(request.reload.status).to eq('waiting_confirmation_for_user')
      end

      it 'set validator for order' do
        subject.run

        order.reload
        expect(order.validator_id_tn).to eq current_user.id_tn
        expect(order.validator_fio).to eq current_user.fullname
      end
    end
  end
end
