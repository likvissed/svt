require 'rails_helper'

module Invent
  RSpec.describe ModelsController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      it 'creates instance of the Models::Index' do
        get :index, format: :json
        expect(assigns(:index)).to be_instance_of Models::Index
      end

      it 'calls :run method' do
        expect_any_instance_of(Models::Index).to receive(:run)
        get :index, format: :json
      end
    end

    describe 'GET #new' do
      it 'creates instance of the Models::NewModel' do
        get :new, format: :json
        expect(assigns(:new_model)).to be_instance_of Models::NewModel
      end

      it 'calls :run method' do
        expect_any_instance_of(Models::NewModel).to receive(:run)
        get :new, format: :json
      end
    end

    describe 'POST #create' do
      let(:model) { build(:model) }
      let(:params) { { model: model.as_json } }

      it 'creates instance of the Models::Create' do
        post :create, params: params
        expect(assigns(:create)).to be_instance_of Models::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(Models::Create).to receive(:run)
        post :create, params: params
      end
    end

    describe 'GET #edit' do
      let!(:model) { create(:model) }
      let(:params) { { model_id: model.model_id } }

      it 'creates instance of the Models::NewModel' do
        get :edit, params: params, format: :json
        expect(assigns(:edit)).to be_instance_of Models::Edit
      end

      it 'calls :run method' do
        expect_any_instance_of(Models::Edit).to receive(:run)
        get :edit, params: params, format: :json
      end
    end

    describe 'PUT #update' do
      let!(:model) { create(:model) }
      let(:params) do
        {
          model_id: model.model_id,
          model: model.as_json
        }
      end

      it 'creates instance of the Models::Update' do
        put :update, params: params
        expect(assigns(:update)).to be_instance_of Models::Update
      end

      it 'calls :run method' do
        expect_any_instance_of(Models::Update).to receive(:run)
        put :update, params: params
      end
    end

    describe 'DELETE #destroy' do
      let!(:model) { create(:model) }
      let(:params) { { model_id: model.model_id } }

      it 'creates instance of the Models::Destroy' do
        delete :destroy, params: params
        expect(assigns(:destroy)).to be_instance_of Models::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Models::Destroy).to receive(:run)
        delete :destroy, params: params
      end
    end
  end
end
