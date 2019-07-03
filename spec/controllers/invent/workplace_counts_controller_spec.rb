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
      let(:user_id) { WorkplaceCount.last.workplace_responsibles.first.user_id }
      let(:user_attr) { User.find(user_id) }
      let(:user_iss_attr) { UserIss.find_by(tn: user.tn) }

      shared_examples 'increments workplace_count' do
        it 'increments count of workplace_count' do
          expect { post :create, params: params }.to change(WorkplaceCount, :count).by(1)
        end
      end

      shared_examples 'users_attributes empty' do
        let(:workplace_count_error) { attributes_for(:active_workplace_count) }

        it 'response with error status 422' do
          post :create, params: { workplace_count: workplace_count_error }

          expect(response.status).to eq(422)
        end
      end

      shared_examples 'user phone is changing' do
        context 'when the phone is entered manually' do
          before { allow(user).to receive(:phone).and_return('50-30') }

          it 'changes phone in User' do
            post :create, params: params

            expect(user.phone).to eq User.find_by(tn: user.tn).phone
          end
        end

        context 'when phone is empty' do
          before { allow(user).to receive(:phone).and_return(nil) }

          it 'the phone is taken from UserIss' do
            post :create, params: params

            expect(User.find_by(tn: user.tn).phone).to eq UserIss.find_by(tn: user.tn).tel
          end
        end
      end

      shared_examples 'attributes id_tn and fullname' do
        it 'creates user with attribute id_tn' do
          post :create, params: params

          expect(user_attr.id_tn).to eq user_iss_attr.id_tn
        end

        it 'creates user with attribute fullname' do
          post :create, params: params

          expect(user_attr.fullname).to eq user_iss_attr.fio
        end
      end

      context 'when creates workplace_count with new user' do
        let(:user) { build(:***REMOVED***_user) }
        let(:workplace_count) { attributes_for(:active_workplace_count, users_attributes: [user.as_json], user_ids: ['']) }
        let(:params) { { workplace_count: workplace_count } }

        include_examples 'increments workplace_count'
        include_examples 'users_attributes empty'
        include_examples 'user phone is changing'
        include_examples 'attributes id_tn and fullname'

        it 'creates user with role :***REMOVED***_user' do
          post :create, params: params

          expect(user_attr.role_id).to eq Role.find_by(name: '***REMOVED***_user').id
        end
      end

      context 'when creates workplace_count with exists user' do
        let(:user) { create(:***REMOVED***_user) }
        let(:workplace_count) { attributes_for(:active_workplace_count, users_attributes: [user.as_json], user_ids: ['']) }
        let(:params) { { workplace_count: workplace_count } }

        include_examples 'increments workplace_count'
        include_examples 'users_attributes empty'
        include_examples 'user phone is changing'
        include_examples 'attributes id_tn and fullname'

        it 'does not change Id user' do
          post :create, params: params

          expect(user_id).to eq user.id
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
