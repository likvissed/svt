require 'rails_helper'

module Warehouse
  RSpec.describe LocationsController, type: :controller do
    sign_in_user
    let(:params) { { start: 0, length: 25 } }

    describe 'GET #load_locations' do
      context 'when IssReferenceSite is present' do
        it 'response value with locations' do
          get :load_locations

          expect(response.status).to eq(200)
        end
      end

      context 'when IssReferenceSite is empty' do
        before { allow_any_instance_of(Invent::LkInvents::InitProperties).to receive(:load_locations).and_return(nil) }

        it 'response with error status' do
          get :load_locations

          expect(response.status).to eq(422)
        end
      end
    end
  end
end
