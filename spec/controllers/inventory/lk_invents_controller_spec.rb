require 'rails_helper'

module Inventory
  RSpec.describe LkInventsController, type: :controller do
    let(:user) { build :user }
    let!(:workplace_count) { create(:active_workplace_count, user: user) }
    sign_in_through_***REMOVED***_user
    before do
      allow(controller).to receive(:check_***REMOVED***_authorization).and_return(true)
      session[:id_tn] = user.id_tn
    end

    describe 'GET #init_properties' do
      it 'creates instance of the LkInvents::InitProperties class' do
        get :init_properties, params: { id_tn: user.id_tn }
        expect(assigns(:properties)).to be_instance_of LkInvents::InitProperties
      end
    end

    describe 'GET #show_division_data' do
      it 'creates instance of the LkInvents::ShowDivisionData class' do
        get :show_division_data, params: { id_tn: user.id_tn, division: workplace_count.division }
        expect(assigns(:division)).to be_instance_of LkInvents::ShowDivisionData
      end
    end

    describe 'GET #pc_config_from_audit' do
      let(:item) { build(:item) }

      it 'creates instance of the LkInvents::PcConfigFromAudit class' do
        get :pc_config_from_audit, params: { id_tn: user.id_tn, invent_num: item.invent_num }
        expect(assigns(:pc_config)).to be_instance_of LkInvents::PcConfigFromAudit
      end
    end

    describe 'POST #create_workplace' do
      let(:workplace) { workplace_attributes }
      let(:file) do
        Rack::Test::UploadedFile.new(
          Rails.root.join('spec', 'files', 'old_pc_config.txt'),
          'text/plain'
        )
      end
      before { post :create_workplace, params: { id_tn: user.id_tn, workplace: workplace.to_json, pc_file: file } }

      it 'create instance of the LkInvents::CreateWorkplace' do
        expect(assigns(:workplace)).to be_instance_of LkInvents::CreateWorkplace
      end

      it 'returns object with %w[workplace, full_message] keys' do
        expect(response.body).to include('workplace', 'full_message')
      end
    end

    describe 'GET #edit_workplace' do
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      before { get :edit_workplace, params: { id_tn: user.id_tn, workplace_id: workplace.workplace_id } }

      it 'create instance of the LkInvents::EditWorkplace' do
        expect(assigns(:workplace)).to be_instance_of LkInvents::EditWorkplace
      end

      it 'returns object at_least with %w[workplace_id] keys' do
        puts response.body.class.name
        expect(response.body).to include('workplace_id')
      end
    end
  end
end
