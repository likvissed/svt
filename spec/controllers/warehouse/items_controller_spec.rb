require 'rails_helper'

module Warehouse
  RSpec.describe ItemsController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      it 'creates instance of the Items::Index' do
        get :index, format: :json
        expect(assigns(:index)).to be_instance_of Items::Index
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Index).to receive(:run)
        get :index, format: :json
      end
    end
  end
end
