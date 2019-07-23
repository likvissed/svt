require 'rails_helper'

module Warehouse
  RSpec.describe ItemsController, type: :controller do
    sign_in_user
    let(:params) { { start: 0, length: 25 } }

    describe 'GET #index' do
      it 'creates instance of the Items::Index' do
        get :index, params: params, format: :json
        expect(assigns(:index)).to be_instance_of Items::Index
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Index).to receive(:run)
        get :index, params: params, format: :json
      end
    end

    describe 'GET #edit' do
      let(:item) { create(:new_item) }

      it 'calls :run method' do
        expect_any_instance_of(Items::Edit).to receive(:run)

        get :edit, params: { id: item.id }, format: :json
      end

      context 'when method :run returns true' do
        before { allow_any_instance_of(Items::Edit).to receive(:run).and_return(true) }

        it 'response with success status' do
          get :edit, params: { id: item.id }, format: :json

          expect(response.status).to eq(200)
        end
      end

      context 'when method :run returns false' do
        before { allow_any_instance_of(Items::Edit).to receive(:run).and_return(false) }

        it 'response with error status' do
          get :edit, params: { id: item.id }, format: :json

          expect(response.status).to eq(422)
        end
      end
    end
  end
end
