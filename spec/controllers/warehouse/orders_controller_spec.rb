require 'rails_helper'

module Warehouse
  RSpec.describe OrdersController, type: :controller do
    sign_in_user

    describe 'GET #index' do
    end

    describe 'GET #new' do
      it 'creates instance of the Orders::NewOrder' do
        get :new, params: { operation: :in }, format: :json
        expect(assigns(:new_order)).to be_instance_of Orders::NewOrder
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::NewOrder).to receive(:run)
        get :new, params: { operation: :in }, format: :json
      end
    end

    describe 'POST #create' do
      it 'creates instance of the Orders::Create' do
        post :create, params: {  }, format: :json
        expect(assigns(:create)).to be_instance_of Orders::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Create).to receive(:run)
        get :new, params: {  }, format: :json
      end
    end
  end
end
