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
  end
end
