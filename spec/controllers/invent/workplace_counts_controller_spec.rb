require 'rails_helper'

module Invent
  RSpec.describe WorkplaceCountsController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      context 'when html request' do
        it 'renders index view' do
          get :index
          expect(response).to render_template :index
        end
      end

      context 'with json request' do
        it 'creates instance of the WorkplaceCounts::Index class' do
          get :index, format: :json
          expect(assigns(:index)).to be_instance_of WorkplaceCounts::Index
        end

        it 'calls :run method' do
          expect_any_instance_of(WorkplaceCounts::Index).to receive(:run)
          get :index, format: :json
        end
      end
    end

    describe 'POST #create' do
      it 'creates instance of the WorkplaceCounts::Create' do
        post :create, params: { workplace_count: { workplace_count_id: 1 } }
        expect(assigns(:create)).to be_instance_of WorkplaceCounts::Create
      end

      it 'calls :run method' do
        expect_any_instance_of(WorkplaceCounts::Create).to receive(:run)
        post :create, params: { workplace_count: { workplace_count_id: 1 } }
      end
    end

    describe 'POST #create_list' do
      let(:file) do
        Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'old_pc_config.txt'), 'text/plain')
      end

      it 'creates instance of the WorkplaceCounts::CreateList' do
        post :create_list, params: { file: file }
        expect(assigns(:create_list)).to be_instance_of WorkplaceCounts::CreateList
      end

      it 'calls :run method' do
        expect_any_instance_of(WorkplaceCounts::CreateList).to receive(:run)
        post :create_list
      end
    end

    describe 'GET #show' do
      let(:user) { create :***REMOVED***_user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }

      it 'creates instance of the WorkplaceCounts::Show' do
        get :show, params: { workplace_count_id: workplace_count.workplace_count_id }
        expect(assigns(:show)).to be_instance_of WorkplaceCounts::Show
      end

      it 'calls :run method' do
        expect_any_instance_of(WorkplaceCounts::Show).to receive(:run)
        get :show, params: { workplace_count_id: workplace_count.workplace_count_id }
      end
    end

    describe 'PUT #update' do
      let(:user) { create :***REMOVED***_user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }

      it 'creates instance of the WorkplaceCounts::Update' do
        put :update, params: { workplace_count_id: workplace_count.workplace_count_id, workplace_count: { division: ***REMOVED*** } }
        expect(assigns(:update)).to be_instance_of WorkplaceCounts::Update
      end

      it 'calls :run method' do
        expect_any_instance_of(WorkplaceCounts::Update).to receive(:run)
        put :update, params: { workplace_count_id: workplace_count.workplace_count_id, workplace_count: { division: ***REMOVED*** } }
      end
    end

    describe 'DELETE #destroy' do
      let(:user) { create :***REMOVED***_user }
      let!(:workplace_count) { create :active_workplace_count, users: [user] }

      it 'creates instance of the WorkplaceCount' do
        delete :destroy, params: { workplace_count_id: workplace_count.workplace_count_id }
        expect(assigns(:workplace_count)).to be_instance_of WorkplaceCount
      end

      it 'destroy record from the WorkplaceCount table' do
        expect { delete :destroy, params: { workplace_count_id: workplace_count.workplace_count_id } }
          .to change(WorkplaceCount, :count).by(-1)
      end
    end
  end
end