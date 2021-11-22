require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe AssignNewExecutor, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:user) }
      let(:request) { create(:request_category_one) }
      let(:user_worker) { attributes_for(:shatunova_user).stringify_keys }

      subject { AssignNewExecutor.new(current_user, request.request_id, user_worker) }

      it 'updates executor_fio and executor_tn attributes' do
        subject.run

        expect(request.reload.executor_fio).to eq(user_worker['fullname'])
        expect(request.reload.executor_tn).to eq(user_worker['tn'])
      end
    end
  end
end
