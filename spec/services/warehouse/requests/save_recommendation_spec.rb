require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe SaveRecommendation, type: :model do
      skip_users_reference
      before { allow(Orbita).to receive(:add_event) }

      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let(:new_recommendation) { [{ 'name': 'RAM 4Gb' }.stringify_keys] }
      let(:request_params) do
        req = attributes_for(:request_category_one)
        req[:recommendation_json] = new_recommendation
        req
      end

      subject { SaveRecommendation.new(current_user, request.request_id, request_params) }

      it 'updates field :recommendation_json' do
        subject.run

        expect(request.reload.recommendation_json).to eq(new_recommendation)
      end

      it 'status request updates as :send_to_owner' do
        subject.run

        expect(request.reload.status).to eq('send_to_owner')
      end

      context 'when recommendation_json is blank' do
        let!(:new_recommendation) { [] }

        it 'adds error :request_is_close' do
          subject.run

          expect(subject.error[:full_message]).to eq 'Recommendation Json не может быть пустым'
        end
      end
    end
  end
end
