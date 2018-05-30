require 'rails_helper'

module Invent
  RSpec.describe WorkplacesController, type: :controller do
    sign_in_user
    let!(:workplace_count) { create(:active_workplace_count, users: [@user]) }

    describe 'GET #index' do
      context 'when html request' do
        it 'renders index view' do
          get :index
          expect(response).to render_template :index
        end
      end

      context 'when json request' do
        it 'creates instance of the Workplaces::Index' do
          get :index, format: :json, params: { search: { value: '', regex: 'false' }, draw: 1, start: 0, length: 25 }
          expect(assigns(:index)).to be_instance_of Workplaces::Index
        end

        it 'calls :run method' do
          expect_any_instance_of(Workplaces::Index).to receive(:run)
          get :index, format: :json
        end
      end
    end

    describe 'GET #new' do
      context 'when html request' do
        it 'creates session variable' do
          get :new, format: :html
          expect(session).to include(:workplace_prev_url)
        end
      end

      context 'when json request' do
        it 'creates instance of the Workplaces::NewWp' do
          get :new, format: :json
          expect(assigns(:new_wp)).to be_instance_of Workplaces::NewWp
        end

        it 'calls :run method' do
          expect_any_instance_of(Workplaces::NewWp).to receive(:run)
          get :new, format: :json
        end
      end
    end

    describe 'POST #create' do
      let(:workplace) { build(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }
      let(:wp_params) { { workplace: workplace.as_json } }

      it 'creates instance of the LkInvents::CreateWorkplace' do
        post :create, params: wp_params
        expect(assigns(:create)).to be_instance_of Workplaces::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::Create).to receive(:run)
        post :create, params: wp_params
      end
    end

    # describe 'GET #list_wp' do
    #   context 'when html request' do
    #     it 'renders list_wp view' do
    #       get :list_wp
    #       expect(response).to render_template :list_wp
    #     end
    #   end

    #   context 'when json request' do
    #     it 'creates instance of the Workplaces::Index' do
    #       get :list_wp, format: :json, params: { init_filters: false, filters: false }
    #       expect(assigns(:list_wp)).to be_instance_of Workplaces::ListWp
    #     end

    #     it 'calls :run method' do
    #       expect_any_instance_of(Workplaces::ListWp).to receive(:run)
    #       get :list_wp, format: :json, params: { init_filters: false, filters: false }
    #     end
    #   end
    # end

    describe 'GET #pc_config_from_audit' do
      it 'creates instance of the LkInvents::PcConfigFromAudit' do
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

      # it 'creates instance of the LkInvents::PcConfigFromUser' do
      #   get :pc_config_from_user, params: { pc_file: file }
      #   expect(assigns(:pc_file)).to be_instance_of LkInvents::PcConfigFromUser
      # end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::PcConfigFromUser).to receive(:run)
        post :pc_config_from_user, params: { pc_file: file }
      end
    end

    describe 'GET #edit' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }

      it 'creates instance of the LkInvents::PcConfigFromAudit' do
        get :edit, params: { workplace_id: workplace.workplace_id }
        expect(assigns(:edit)).to be_instance_of Workplaces::Edit
      end

      context 'when html request' do
        before { get :edit, params: { workplace_id: workplace } }

        it 'assigns the requested workplace to @workplace' do
          expect(assigns(:workplace)).to eq workplace
        end

        it 'creates session variable' do
          get :new, format: :html
          expect(session).to include(:workplace_prev_url)
        end

        it 'renders edit page' do
          expect(response).to render_template :edit
        end
      end

      context 'when json request' do
        it 'calls :run method' do
          expect_any_instance_of(Workplaces::Edit).to receive(:run)
          get :edit, params: { workplace_id: workplace.workplace_id }
        end
      end
    end

    describe 'PUT #update' do
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      let(:wp_params) do
        {
          workplace_id: workplace.workplace_id,
          workplace: workplace.as_json
        }
      end

      it 'creates instance of the LkInvents::UpdateWorkplace' do
        put :update, params: wp_params
        expect(assigns(:update)).to be_instance_of Workplaces::Update
      end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::Update).to receive(:run)
        put :update, params: wp_params
      end
    end

    describe 'DELETE #destroy' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }
      let(:params) { { workplace_id: workplace.workplace_id } }
      subject { delete :destroy, params: { workplace_id: workplace.workplace_id } }

      it 'creates instance of the Workplaces::Destroy' do
        delete :destroy, params: params
        expect(assigns(:destroy)).to be_instance_of Workplaces::Destroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::Destroy).to receive(:run)
        delete :destroy, params: params
      end
    end

    describe 'DELETE #hard_destroy' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count) }
      let(:params) { { workplace_id: workplace.workplace_id } }
      let(:address) { 'prev_address' }
      let(:session_obj) { { workplace_prev_url: address } }
      let(:response_obj) { { location: address } }

      it 'creates instance of the Workplaces::HardDestroy' do
        delete :hard_destroy, params: params
        expect(assigns(:hard_destroy)).to be_instance_of Workplaces::HardDestroy
      end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::HardDestroy).to receive(:run)
        delete :hard_destroy, params: params
      end

      it 'responces with :location variable' do
        delete :hard_destroy, params: params, session: session_obj
        expect(response.body).to eq response_obj.to_json
      end
    end

    describe 'PUT #confirm' do
      it 'creates instance of the LkInvents::PcConfigFromAudit' do
        put :confirm
        expect(assigns(:confirm)).to be_instance_of Workplaces::Confirm
      end

      it 'calls :run method' do
        expect_any_instance_of(Workplaces::Confirm).to receive(:run)
        put :confirm
      end
    end
  end
end
