require 'rails_helper'

module Inventory
  RSpec.describe LkInventsController, type: :controller do
    # sign_in_through_***REMOVED***_user
    let(:***REMOVED***_user) { create :user }
    let!(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
    let(:***REMOVED***_auth) { LkInvents::LkAuthorization.new('sid') }
    before do
      allow(LkInvents::LkAuthorization).to receive(:new).and_return(***REMOVED***_auth)
      allow(***REMOVED***_auth).to receive(:run).and_return(true)
      allow(***REMOVED***_auth).to receive(:data).and_return(***REMOVED***_user)
    end

    describe 'GET #init_properties' do
      it 'creates instance of the LkInvents::InitProperties class' do
        get :init_properties
        expect(assigns(:properties)).to be_instance_of LkInvents::InitProperties
      end
    end

    describe 'GET #show_division_data' do
      it 'creates instance of the LkInvents::ShowDivisionData class' do
        get :show_division_data, params: { division: workplace_count.division }
        expect(assigns(:division)).to be_instance_of LkInvents::ShowDivisionData
      end
    end

    describe 'GET #pc_config_from_audit' do
      let(:item) { build :item }

      it 'creates instance of the LkInvents::PcConfigFromAudit class' do
        get :pc_config_from_audit, params: { invent_num: item.invent_num }
        expect(assigns(:pc_config)).to be_instance_of LkInvents::PcConfigFromAudit
      end
    end

    describe 'POST #create_workplace' do
      let(:workplace) { create_workplace_attributes room: build(:iss_room) }
      let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'old_pc_config.txt'), 'text/plain') }
      before { post :create_workplace, params: { workplace: workplace.to_json, pc_file: file } }

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
      before { get :edit_workplace, params: { workplace_id: workplace.workplace_id } }

      it 'create instance of the LkInvents::EditWorkplace' do
        expect(assigns(:workplace)).to be_instance_of LkInvents::EditWorkplace
      end

      it 'returns object at_least with %w[workplace_id] keys' do
        expect(response.body).to include('workplace_id')
      end
    end

    describe 'PATCH #update_workplace' do
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'old_pc_config.txt'), 'text/plain') }
      let(:new_workplace) { update_workplace_attributes(***REMOVED***_user, workplace.workplace_id, room: build(:iss_room), user_iss: ***REMOVED***_user) }
      before do
        patch :update_workplace,
              params: {
                workplace_id: workplace.workplace_id,
                workplace: new_workplace.to_json,
                pc_file: file
              }
      end

      it 'create instance of the LkInvents::EditWorkplace' do
        expect(assigns(:workplace)).to be_instance_of LkInvents::UpdateWorkplace
      end

      it 'returns object with %w[workplace full_message] keys' do
        expect(response.body).to include('workplace', 'full_message')
      end
    end

    describe 'DELETE #delete_workplace' do
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end

      it 'create instance of the LkInvents::DestroyWorkplace' do
        delete :destroy_workplace, params: { workplace_id: workplace.workplace_id }
        expect(assigns(:workplace)).to be_instance_of LkInvents::DestroyWorkplace
      end
    end
  end
end
