require 'feature_helper'

module Warehouse
  module Requests
    RSpec.describe Update, type: :model do
      let(:current_user) { create(:***REMOVED***_user) }
      let(:request) { create(:request_category_one) }
      let(:request_params) do
        req = attributes_for(:request_category_one)
        req[:comment] = 'new text'
        req
      end

      subject { Update.new(current_user, request.request_id, request_params) }

      it 'updates status for request' do
        subject.run

        expect(request.reload.comment).to eq(request_params[:comment])
      end

      context 'when status is :completed for request' do
        before { request_params[:status] = 'completed' }

        it 'adds error :request_is_close' do
          subject.run

          expect(subject.error[:full_message]).to eq 'Невозможно обновить комментарий у закрытой заявки'
        end
      end
    end
  end
end
