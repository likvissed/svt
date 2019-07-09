require 'rails_helper'

module Invent
  RSpec.describe WorkplaceCountsController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      let(:user) { create(:***REMOVED***_user) }
      let!(:workplace_count) do
        wc = build_list(:active_workplace_count, 30, users: [user])
        wc.each do |dept|
          dept.save(validate: false)
        end
        wc
      end

      it 'renders index view format :html' do
        get :index, format: :html

        expect(response).to render_template :index
      end

      it 'response with success status' do
        get :index

        expect(response.status).to eq(200)
      end

      %w[division user_fullname user_phone user_time status_name pending_verification confirmed freezed].each do |i|
        it "has :#{i} attribute" do
          get :index, format: :json

          expect(JSON.parse(response.body)['array'].first.key?(i)).to be_truthy
        end
      end

      it 'count records on first page' do
        get :index, params: { start: 0, length: 25 }, format: :json

        expect(JSON.parse(response.body)['array'].count).to eq(25)
      end

      it 'count records on last page' do
        get :index, params: { start: 25, length: 25 }, format: :json

        expect(JSON.parse(response.body)['array'].count).to eq(5)
      end
    end

    describe 'GET #edit ' do
      let(:user) { create(:***REMOVED***_user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let(:params) { { workplace_count_id: workplace_count.workplace_count_id } }

      %w[user_ids users_attributes].each do |attr|
        it "includes the filed '#{attr}''" do
          get :edit, params: params, format: :json

          expect(response.body).to have_json_path(attr)
        end
      end

      it "does no include the field 'users'" do
        get :edit, params: params, format: :json

        expect(response.body).to_not have_json_path('users')
      end
    end

    describe 'GET #new ' do
      %w[user_ids users_attributes].each do |attr|
        it "includes the filed '#{attr}'" do
          get :new

          expect(response.body).to have_json_path(attr)
        end
      end
    end

    describe 'POST #create ' do
      let(:workplace_count) { attributes_for(:active_workplace_count) }
      let(:params) { { workplace_count: workplace_count } }

      it 'calls :run method' do
        expect_any_instance_of(WorkplaceCounts::Create).to receive(:run)
        post :create, params: params
      end

      context 'when method :run returns true' do
        before { allow_any_instance_of(WorkplaceCounts::Create).to receive(:run).and_return(true) }

        it 'response with success status' do
          post :create, params: params

          expect(response.status).to eq(200)
        end
      end

      context 'when method :run returns false' do
        before { allow_any_instance_of(WorkplaceCounts::Create).to receive(:run).and_return(false) }

        it 'response with error status' do
          post :create, params: params

          expect(response.status).to eq(422)
        end
      end
    end

    describe 'PUT #update' do
      let(:user) { create(:***REMOVED***_user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [user]).as_json }
      let(:params) { { workplace_count_id: workplace_count['workplace_count_id'], workplace_count: workplace_count } }

      it 'calls :run method' do
        expect_any_instance_of(WorkplaceCounts::Update).to receive(:run)
        put :update, params: params
      end

      context 'when method :run returns true' do
        before { allow_any_instance_of(WorkplaceCounts::Update).to receive(:run).and_return(true) }

        it 'response with success status' do
          put :update, params: params

          expect(response.status).to eq(200)
        end
      end

      context 'when method :run returns false' do
        before { allow_any_instance_of(WorkplaceCounts::Update).to receive(:run).and_return(false) }

        it 'response with error status' do
          put :update, params: params

          expect(response.status).to eq(422)
        end
      end
    end

    describe 'DELETE #destroy' do
      let(:user1) { create(:***REMOVED***_user) }
      let(:user2) { create(:***REMOVED***_user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [user1, user2]) }
      let(:params) { { workplace_count_id: workplace_count.workplace_count_id } }

      it 'reduce count of workplace_count' do
        expect { delete :destroy, params: params }.to change(WorkplaceCount, :count).by(-1)
      end

      it 'reduce count of workplace_responsibles' do
        expect { delete :destroy, params: params }.to change(WorkplaceCount.last.workplace_responsibles, :count).by(-2)
      end

      it 'response with error RecordNotFound' do
        expect { delete :destroy, params: { workplace_count_id: 12 } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
