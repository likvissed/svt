require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  sign_in_user

  describe 'GET #index' do
    it 'creates instance of the Users::Index' do
      get :index, format: :json
      expect(assigns(:index)).to be_instance_of Users::Index
    end

    it 'calls :run method' do
      expect_any_instance_of(Users::Index).to receive(:run)
      get :index, format: :json
    end
  end

  describe 'GET #new' do
    it 'creates instance of the Models::NewUser' do
      get :new, format: :json
      expect(assigns(:new_user)).to be_instance_of Users::NewUser
    end

    it 'calls :run method' do
      expect_any_instance_of(Users::NewUser).to receive(:run)
      get :new, format: :json
    end
  end

  describe 'POST #create' do
    let(:user) { build(:user) }
    let(:params) { { user: user.as_json } }

    it 'creates instance of the Users::Create' do
      post :create, params: params
      expect(assigns(:create)).to be_instance_of Users::Create
    end

    it 'calls :run method' do
      expect_any_instance_of(Users::Create).to receive(:run)
      post :create, params: params
    end
  end

  describe 'GET #edit' do
    let!(:b_user) { create(:***REMOVED***_user) }
    let(:params) { { id: b_user.id } }

    it 'creates instance of the Users::Edit' do
      get :edit, params: params, format: :json
      expect(assigns(:edit)).to be_instance_of Users::Edit
    end

    it 'calls :run method' do
      expect_any_instance_of(Users::Edit).to receive(:run)
      get :edit, params: params, format: :json
    end
  end

  describe 'PUT #update' do
    let!(:b_user) { create(:***REMOVED***_user) }
    let(:params) do
      {
        id: b_user.id,
        user: b_user.as_json
      }
    end

    it 'creates instance of the Users::Update' do
      put :update, params: params
      expect(assigns(:update)).to be_instance_of Users::Update
    end

    it 'calls :run method' do
      expect_any_instance_of(Users::Update).to receive(:run)
      put :update, params: params
    end
  end

  describe 'DELETE #destroy' do
    let!(:b_user) { create(:***REMOVED***_user) }
    let(:params) { { id: b_user.id } }

    it 'creates instance of the Users::Destroy' do
      delete :destroy, params: params
      expect(assigns(:destroy)).to be_instance_of Users::Destroy
    end

    it 'calls :run method' do
      expect_any_instance_of(Users::Destroy).to receive(:run)
      delete :destroy, params: params
    end
  end
end
