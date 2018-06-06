require 'rails_helper'

module Invent
  RSpec.describe LkInventsController, type: :controller do
    # sign_in_through_***REMOVED***_user
    let(:***REMOVED***_user) { create(:user) }
    let!(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
    let(:***REMOVED***_auth) { LkInvents::LkAuthorization.new('sid') }
    before do
      allow(LkInvents::LkAuthorization).to receive(:new).and_return(***REMOVED***_auth)
      allow(***REMOVED***_auth).to receive(:run).and_return(true)
      allow(***REMOVED***_auth).to receive(:data).and_return(***REMOVED***_user)
    end

    describe 'GET #svt_access' do
      it 'creates instance of the LkInvents::SvtAccess' do
        get :svt_access, params: { tn: ***REMOVED*** }
        expect(assigns(:svt_access)).to be_instance_of LkInvents::SvtAccess
      end

      it 'calls :run method' do
        expect_any_instance_of(LkInvents::SvtAccess).to receive(:run)
        get :svt_access, params: { tn: ***REMOVED*** }
      end
    end

    describe 'GET #init_properties' do
      it 'creates instance of the LkInvents::InitProperties' do
        get :init_properties
        expect(assigns(:properties)).to be_instance_of LkInvents::InitProperties
      end

      it 'calls :run method' do
        expect_any_instance_of(LkInvents::InitProperties).to receive(:run)
        get :init_properties
      end
    end

    describe 'GET #show_division_data' do
      it 'creates instance of the LkInvents::ShowDivisionData' do
        get :show_division_data, params: { division: workplace_count.division }
        expect(assigns(:division)).to be_instance_of LkInvents::ShowDivisionData
      end

      it 'calls :run method' do
        expect_any_instance_of(LkInvents::ShowDivisionData).to receive(:run)
        get :show_division_data, params: { division: workplace_count.division }
      end
    end

    describe 'GET #pc_config_from_audit' do
      it 'creates instance of the Workplaces::PcConfigFromAudit' do
        get :pc_config_from_audit, params: { invent_num: 111_222 }
        expect(assigns(:pc_config)).to be_instance_of Workplaces::PcConfigFromAudit
      end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::PcConfigFromAudit).to receive(:run)
        get :pc_config_from_audit, params: { invent_num: 111_222 }
      end
    end

    describe 'GET #pc_config_from_user' do
      let(:file) do
        Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'old_pc_config.txt'), 'text/plain')
      end

      # FIXME: Спека падает
      # it 'creates instance of the LkInvents::PcConfigFromUser' do
      #   get :pc_config_from_user, params: { pc_file: file }
      #   expect(assigns(:pc_file)).to be_instance_of LkInvents::PcConfigFromUser
      # end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::PcConfigFromUser).to receive(:run)
        post :pc_config_from_user, params: { pc_file: file }
      end
    end

    # describe 'POST #create_workplace' do
    #   let(:workplace) do
    #     build(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
    #   end
    #   let(:wp_params) { { workplace: workplace.as_json } }

    #   it 'creates instance of the Workplaces::Create' do
    #     post :create_workplace, params: wp_params
    #     expect(assigns(:workplace)).to be_instance_of Workplaces::Create
    #   end

    #   it 'calls :run method' do
    #     expect_any_instance_of(Workplaces::Create).to receive(:run)
    #     post :create_workplace, params: wp_params
    #   end
    # end

    # describe 'GET #edit_workplace' do
    #   let!(:workplace) do
    #     create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
    #   end

    #   it 'creates instance of the LkInvents::EditWorkplace' do
    #     get :edit_workplace, params: { workplace_id: workplace.workplace_id }
    #     expect(assigns(:workplace)).to be_instance_of LkInvents::EditWorkplace
    #   end

    #   it 'calls :run method' do
    #     expect_any_instance_of(LkInvents::EditWorkplace).to receive(:run)
    #     get :edit_workplace, params: { workplace_id: workplace.workplace_id }
    #   end
    # end

    # describe 'PUT #update_workplace' do
    #   let!(:workplace) do
    #     create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
    #   end
    #   let(:wp_params) do
    #     {
    #       workplace_id: workplace.workplace_id,
    #       workplace: workplace.as_json
    #     }
    #   end

    #   it 'creates instance of the Workplaces::Update' do
    #     put :update_workplace, params: wp_params
    #     expect(assigns(:workplace)).to be_instance_of Workplaces::Update
    #   end

    #   it 'calls :run method' do
    #     expect_any_instance_of(Workplaces::Update).to receive(:run)
    #     put :update_workplace, params: wp_params
    #   end
    # end

    # describe 'DELETE #destroy_workplace' do
    #   let!(:workplace) do
    #     create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
    #   end

    #   it 'create instance of the LkInvents::DestroyWorkplace' do
    #     delete :destroy_workplace, params: { workplace_id: workplace.workplace_id }
    #     expect(assigns(:workplace)).to be_instance_of LkInvents::DestroyWorkplace
    #   end

    #   it 'calls :run method' do
    #     expect_any_instance_of(LkInvents::DestroyWorkplace).to receive(:run)
    #     delete :destroy_workplace, params: { workplace_id: workplace.workplace_id }
    #   end
    # end

    describe 'GET #generate_pdf' do
      it 'create instance of the LkInvents::DivisionReport' do
        get :generate_pdf, params: { division: ***REMOVED*** }
        expect(assigns(:division_report)).to be_instance_of LkInvents::DivisionReport
      end

      it 'calls :run method' do
        expect_any_instance_of(LkInvents::DivisionReport).to receive(:run)
        get :generate_pdf, params: { division: ***REMOVED*** }
      end
    end

    describe 'GET existing_item' do
      it 'create instance of the InvItem::ExistingItem' do
        get :existing_item, params: { invent_num: '123456' }
        expect(assigns(:existing_item)).to be_instance_of Items::ExistingItem
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::ExistingItem).to receive(:run)
        get :existing_item, params: { invent_num: '123456' }
      end
    end

    # describe 'GET #send_pc_script'
  end
end
