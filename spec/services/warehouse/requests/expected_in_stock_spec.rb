require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe ExpectedInStock, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let(:flag) { true }

      subject { ExpectedInStock.new(current_user, request.request_id, flag) }

      it 'status request updates as :expected_in_stock' do
        subject.run

        expect(request.reload.status).to eq('expected_in_stock')
      end

      context 'when flag is false' do
        let(:flag) { false }

        it 'status request updates as :create_order' do
          subject.run

          expect(request.reload.status).to eq('create_order')
        end
      end
    end
  end
end
