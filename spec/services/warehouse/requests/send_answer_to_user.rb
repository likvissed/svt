require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe SendAnswerToUser, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, operation: :out, request: request)
        ord.save(validate: false)
        ord
      end

      subject { SendAnswerToUser.new(current_user, request.request_id) }
    end
  end
end
