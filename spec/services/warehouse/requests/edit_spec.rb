require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe Edit, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let!(:user_worker) { create(:shatunova_user) }
      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, operation: :out, request: request)
        ord.save(validate: false)
        ord
      end
      let!(:attachment_request) { create(:attachment_request, request: request) }

      subject { Edit.new(current_user, request.request_id) }

      %w[request_items attachments status_translated].each do |i|
        it "has :#{i} attribute" do
          subject.run

          expect(subject.data[:request].key?(i)).to be_truthy
        end
      end

      it 'assigns identifier for each file' do
        subject.run

        expect(subject.data[:request]['attachments'].first['filename']).to eq attachment_request.document.identifier
      end

      it 'the order matches the request' do
        subject.run

        expect(subject.data[:request]['order']['id']).to eq request.order.id
      end
    end
  end
end
