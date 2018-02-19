require 'rails_helper'

module Invent
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

    describe 'GET #busy' do
      let(:params) { { type_id: Invent::Type.first.type_id, invent_num: '123456' } }

      it 'creates instance of the Items::Busy' do
        get :busy, params: params, format: :json
        expect(assigns(:busy)).to be_instance_of Items::Busy
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Busy).to receive(:run)
        get :busy, params: params, format: :json
      end
    end

    describe 'GET #show' do
      let(:item) { create(:item, :with_property_values, type_name: :monitor) }
      let(:params) { { item_id: item.item_id } }

      it 'creates instance of the Items::Show' do
        get :show, params: params, format: :json
        expect(assigns(:show)).to be_instance_of Items::Show
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Show).to receive(:run)
        get :show, params: params, format: :json
      end
    end

    describe 'GET #edit' do
      let(:item) { create(:item, :with_property_values, type_name: :monitor) }
      let(:params) { { item_id: item.item_id } }

      it 'creates instance of the Items::Edit' do
        get :edit, params: params, format: :json
        expect(assigns(:edit)).to be_instance_of Items::Edit
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Edit).to receive(:run)
        get :edit, params: params, format: :json
      end
    end

    describe 'GET #avaliable' do
      let(:params) { { type_id: Invent::Type.first.type_id } }

      it 'creates instance of the Items::Avaliable' do
        get :avaliable, params: params, format: :json
        expect(assigns(:avaliable)).to be_instance_of Items::Avaliable
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Avaliable).to receive(:run)
        get :avaliable, params: params, format: :json
      end
    end
  end
end
