require 'rails_helper'

module Warehouse
  RSpec.describe OrdersController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      it 'creates instance of the Orders::Index' do
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

    describe 'POST #create_in' do
      let(:order) { build(:order) }
      let(:order_params) { { order: order.as_json } }

      it 'creates instance of the Orders::CreateIn' do
        post :create_in, params: order_params, format: :json
        expect(assigns(:create_in)).to be_instance_of Orders::CreateIn
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::CreateIn).to receive(:run)
        post :create_in, params: order_params, format: :json
      end
    end

    describe 'POST #create_out' do
      let(:order) { build(:order) }
      let(:params) { { order: order.as_json } }

      it 'creates instance of the Orders::CreateOut' do
        post :create_out, params: params, format: :json
        expect(assigns(:create_out)).to be_instance_of Orders::CreateOut
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::CreateOut).to receive(:run)
        post :create_out, params: params, format: :json
      end
    end

    describe 'GET #edit' do
      let!(:order) { create(:order) }
      let(:params) { { warehouse_order_id: order.warehouse_order_id } }

      it 'creates instance of the Orders::Edit' do
        get :edit, params: params, format: :json
        expect(assigns(:edit)).to be_instance_of Orders::Edit
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Edit).to receive(:run)
        get :edit, params: params, format: :json
      end
    end

    describe 'PUT #update' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          warehouse_order_id: order.warehouse_order_id,
          order: order.as_json
        }
      end

      it 'creates instance of the Orders::Update' do
        put :update, params: params
        expect(assigns(:update)).to be_instance_of Orders::Update
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Update).to receive(:run)
        put :update, params: params
      end
    end

    describe 'POST #execute_in' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          warehouse_order_id: order.warehouse_order_id,
          order: order.as_json
        }
      end

      it 'creates instance of the Orders::ExecuteIn' do
        post :execute_in, params: params, format: :json
        expect(assigns(:execute_in)).to be_instance_of Orders::ExecuteIn
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::ExecuteIn).to receive(:run)
        post :execute_in, params: params, format: :json
      end
    end

    describe 'POST #execute_out' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          warehouse_order_id: order.warehouse_order_id,
          order: order.as_json
        }
      end

      it 'creates instance of the Orders::ExecuteOut' do
        post :execute_out, params: params, format: :json
        expect(assigns(:execute_out)).to be_instance_of Orders::ExecuteOut
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::ExecuteOut).to receive(:run)
        post :execute_out, params: params, format: :json
      end
    end

    describe 'DELETE #destroy' do
      let!(:order) { create(:order) }
      let(:params) { { warehouse_order_id: order.warehouse_order_id } }

      it 'creates instance of the Orders::Destroy' do
        delete :destroy, params: params, format: :json
        expect(assigns(:destroy)).to be_instance_of Orders::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Destroy).to receive(:run)
        delete :destroy, params: params, format: :json
      end
    end

    describe 'GET #prepare_to_deliver' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          warehouse_order_id: order.warehouse_order_id,
          order: order.as_json
        }
      end

      it 'creates instance of the Orders::PrepareToDeliver' do
        get :prepare_to_deliver, params: params, format: :json
        expect(assigns(:deliver)).to be_instance_of Orders::PrepareToDeliver
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::PrepareToDeliver).to receive(:run)
        get :prepare_to_deliver, params: params, format: :json
      end
    end
  end
end
