require 'rails_helper'

module Invent
  RSpec.describe VendorsController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      let(:vendor) { Vendor.all.order(:vendor_name) }

      it 'loads all vendors' do
        get :index, format: :json
        expect(assigns(:vendors)).to eq vendor
      end
    end

    describe 'POST #create' do
      let(:vendor) { build(:vendor) }
      let(:params) { { vendor: vendor.as_json } }

      it 'creates instance of the Vendors::Create' do
        post :create, params: params
        expect(assigns(:create)).to be_instance_of Vendors::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(Vendors::Create).to receive(:run)
        post :create, params: params
      end
    end

    describe 'DELETE #destroy' do
      let!(:vendor) { create(:vendor) }
      let(:params) { { vendor_id: vendor.vendor_id } }

      it 'creates instance of the Vendors::Destroy' do
        delete :destroy, params: params
        expect(assigns(:destroy)).to be_instance_of Vendors::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Vendors::Destroy).to receive(:run)
        delete :destroy, params: params
      end
    end
  end
end
