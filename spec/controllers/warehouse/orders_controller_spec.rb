require 'rails_helper'

module Warehouse
  RSpec.describe OrdersController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      it 'creates instance of the Orders::NewOrder' do
        get :index, format: :json
        expect(assigns(:index)).to be_instance_of Orders::Index
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Index).to receive(:run)
        get :index, format: :json
      end
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
      let(:order) { build(:order) }
      let(:order_params) { { order: order.as_json } }

      it 'creates instance of the Orders::Create' do
        post :create, params: order_params, format: :json
        expect(assigns(:create)).to be_instance_of Orders::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Create).to receive(:run)
        post :create, params: order_params, format: :json
      end
    end

    describe 'GET #edit' do
      let!(:order) { create(:order) }

      it 'creates instance of the Orders::Edit' do
        get :edit, params: { warehouse_order_id: order.warehouse_order_id }, format: :json
        expect(assigns(:edit)).to be_instance_of Orders::Edit
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Edit).to receive(:run)
        get :edit, params: { warehouse_order_id: order.warehouse_order_id }, format: :json
      end
    end

    describe 'PUT #update'

    describe 'POST #execute' do
      let!(:order) { create(:order) }

      it 'creates instance of the Orders::Execute' do
        post :execute, params: { warehouse_order_id: order.warehouse_order_id, order: order.as_json  }, format: :json
        expect(assigns(:execute)).to be_instance_of Orders::Execute
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Execute).to receive(:run)
        post :execute, params: { warehouse_order_id: order.warehouse_order_id, order: order.as_json }, format: :json
      end
    end

    describe 'DELETE #destroy' do
      let!(:order) { create(:order) }

      it 'creates instance of the Orders::Destroy' do
        delete :destroy, params: { warehouse_order_id: order.warehouse_order_id }, format: :json
        expect(assigns(:destroy)).to be_instance_of Orders::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Destroy).to receive(:run)
        delete :destroy, params: { warehouse_order_id: order.warehouse_order_id }, format: :json
      end
    end
  end
end
