require 'rails_helper'

module Warehouse
  RSpec.describe OrdersController, type: :controller do
    sign_in_user
    let(:params) { { start: 0, length: 25 } }

    describe 'GET #index_in' do
      let(:index) { Orders::Index.new(params) }

      it 'creates instance of the Orders::Index' do
        get :index_in, format: :json
        expect(assigns(:index)).to be_instance_of Orders::Index
      end

      it 'calls :run method' do
        expect(Orders::Index).to receive(:new).with(anything, operation: :in, status: :processing).and_return(index)
        expect(index).to receive(:run)
        get :index_in, format: :json
      end
    end

    describe 'GET #index_out' do
      let(:index) { Orders::Index.new(params) }

      it 'creates instance of the Orders::Index' do
        get :index_out, format: :json
        expect(assigns(:index)).to be_instance_of Orders::Index
      end

      it 'calls :run method' do
        expect(Orders::Index).to receive(:new).with(anything, operation: :out, status: :processing).and_return(index)
        expect(index).to receive(:run)
        get :index_out, format: :json
      end
    end

    describe 'GET #archive' do
      let(:index) { Orders::Index.new(params) }

      it 'creates instance of the Orders::Index' do
        get :archive, format: :json
        expect(assigns(:index)).to be_instance_of Orders::Index
      end

      it 'calls :run method' do
        expect(Orders::Index).to receive(:new).with(anything, status: :done).and_return(index)
        expect(index).to receive(:run)
        get :archive, format: :json
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

    describe 'POST #create_write_off' do
      let(:order) { build(:order) }
      let(:params) { { order: order.as_json } }

      it 'creates instance of the Orders::CreateWriteOff' do
        post :create_write_off, params: params, format: :json
        expect(assigns(:create_write_off)).to be_instance_of Orders::CreateWriteOff
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::CreateWriteOff).to receive(:run)
        post :create_write_off, params: params, format: :json
      end
    end

    describe 'GET #edit' do
      let!(:order) { create(:order) }
      let(:params) { { id: order.id } }

      it 'creates instance of the Orders::Edit' do
        get :edit, params: params, format: :json
        expect(assigns(:edit)).to be_instance_of Orders::Edit
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Edit).to receive(:run)
        get :edit, params: params, format: :json
      end
    end

    describe 'PUT #update_in' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          id: order.id,
          order: order.as_json
        }
      end

      it 'creates instance of the Orders::UpdateIn' do
        put :update_in, params: params
        expect(assigns(:update_in)).to be_instance_of Orders::UpdateIn
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::UpdateIn).to receive(:run)
        put :update_in, params: params
      end
    end

    describe 'PUT #update_out' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          id: order.id,
          order: order.as_json
        }
      end

      it 'creates instance of the Orders::UpdateOut' do
        put :update_out, params: params
        expect(assigns(:update_out)).to be_instance_of Orders::UpdateOut
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::UpdateOut).to receive(:run)
        put :update_out, params: params
      end
    end

    describe 'PUT #confirm_out' do
      let!(:order) { create(:order) }
      let(:params) { { id: order.id } }

      it 'creates instance of the Orders::ConfirmOut' do
        put :confirm_out, params: params
        expect(assigns(:confirm_out)).to be_instance_of Orders::ConfirmOut
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::ConfirmOut).to receive(:run)
        put :confirm_out, params: params
      end
    end

    describe 'POST #execute_in' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          id: order.id,
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
          id: order.id,
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
      let(:params) { { id: order.id } }

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
          id: order.id,
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

    describe 'GET #print' do
      let!(:order) { create(:order) }
      let(:params) do
        {
          id: order.id,
          order: order.to_json
        }
      end

      it 'creates instance of the Orders::Print' do
        get :print, params: params, format: :json
        expect(assigns(:print)).to be_instance_of Orders::Print
      end

      it 'calls :run method' do
        expect_any_instance_of(Orders::Print).to receive(:run)
        get :print, params: params, format: :json
      end
    end
  end
end
