require 'rails_helper'

module Warehouse
  RSpec.describe SuppliesController, type: :controller do
    sign_in_user
    let(:params) { { start: 0, length: 25 } }

    describe 'GET #index' do
      let(:index) { Supplies::Index.new(params) }

      it 'creates instance of the Supplies::Index' do
        get :index, format: :json
        expect(assigns(:index)).to be_instance_of Supplies::Index
      end

      it 'calls :run method' do
        expect_any_instance_of(Supplies::Index).to receive(:run)
        get :index, format: :json
      end
    end

    describe 'GET #new' do
      it 'creates instance of the Supplies::NewSupply' do
        get :new, format: :json
        expect(assigns(:new_supply)).to be_instance_of Supplies::NewSupply
      end

      it 'calls :run method' do
        expect_any_instance_of(Supplies::NewSupply).to receive(:run)
        get :new, format: :json
      end
    end

    describe 'POST #create' do
      let(:supply) { build(:supply) }
      let(:params) { { supply: supply.as_json } }

      it 'creates instance of the Supplies::Create' do
        post :create, params: params, format: :json
        expect(assigns(:create)).to be_instance_of Supplies::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(Supplies::Create).to receive(:run)
        post :create, params: params, format: :json
      end
    end

    describe 'PUT #update' do
      let!(:supply) { create(:supply) }
      let(:params) do
        {
          id: supply.id,
          supply: supply.as_json
        }
      end

      it 'creates instance of the Supplies::Update' do
        put :update, params: params
        expect(assigns(:update)).to be_instance_of Supplies::Update
      end

      it 'calls :run method' do
        expect_any_instance_of(Supplies::Update).to receive(:run)
        put :update, params: params
      end
    end

    describe 'DELETE #destroy' do
      let!(:supply) { create(:supply) }
      let(:params) { { id: supply.id } }

      it 'creates instance of the Supplies::Destroy' do
        delete :destroy, params: params, format: :json
        expect(assigns(:destroy)).to be_instance_of Supplies::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Supplies::Destroy).to receive(:run)
        delete :destroy, params: params, format: :json
      end
    end
  end
end
