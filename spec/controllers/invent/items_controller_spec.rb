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
      let!(:item) { create(:item, :with_property_values, type_name: :monitor) }
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

    describe 'PUT #update' do
      let!(:item) { create(:item, :with_property_values, type_name: :monitor) }
      let(:params) do
        {
          item_id: item.item_id,
          item: item.as_json
        }
      end

      it 'creates instance of the Items::Update' do
        put :update, params: params
        expect(assigns(:update)).to be_instance_of Items::Update
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Update).to receive(:run)
        put :update, params: params
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

    describe 'DELETE #destroy' do
      let!(:item) { create(:item, :with_property_values, type_name: :monitor) }
      let(:params) { { item_id: item.item_id } }

      it 'creates instance of the Items::Destroy' do
        delete :destroy, params: params
        expect(assigns(:destroy)).to be_instance_of Items::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Destroy).to receive(:run)
        delete :destroy, params: params
      end
    end

    describe 'GET #pc_config_from_audit' do
      it 'creates instance of the LkInvents::PcConfigFromAudit' do
        get :pc_config_from_audit, params: { invent_num: 111_222 }
        expect(assigns(:pc_config)).to be_instance_of Items::PcConfigFromAudit
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::PcConfigFromAudit).to receive(:run)
        get :pc_config_from_audit, params: { invent_num: 111_222 }
      end
    end

    describe 'GET #pc_config_from_user' do
      let(:file) do
        Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'old_pc_config.txt'), 'text/plain')
      end

      # it 'creates instance of the LkInvents::PcConfigFromUser' do
      #   get :pc_config_from_user, params: { pc_file: file }
      #   expect(assigns(:pc_file)).to be_instance_of LkInvents::PcConfigFromUser
      # end

      it 'calls :run method' do
        expect_any_instance_of(Items::PcConfigFromUser).to receive(:run)
        post :pc_config_from_user, params: { pc_file: file }
      end
    end
  end
end
