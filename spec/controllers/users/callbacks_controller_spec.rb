require 'rails_helper'

module Users
  RSpec.describe CallbacksController, type: :controller do
    before :each do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end

    describe 'GET #registration_user' do
      before { get :registration_user, format: :html }

      let(:auth_center_path) { "#{ENV['AUTHORIZATION_URI']}?client_id=#{ENV['CLIENT_ID']}&response_type=code&redirect_uri=#{ENV['REDIRECT_URI']}&state=#{session[:state]}" }

      it 'redirect in auth-center' do
        expect(response).to redirect_to auth_center_path
      end

      it 'receives a response with status 301' do
        expect(response.status).to eq(302)
      end

      it 'check for session parameter state for session' do
        expect(session[:state]).to be_present
      end
    end

    describe 'POST #authorize_user' do
      context 'when attributes is valid' do
        sign_in_user
        before { post :authorize_user, format: :json }

        it { should set_flash[:notice].to 'Вход в систему выполнен' }
      end

      context 'when attributes is invalid' do
        before { post :authorize_user, params: { error: 'example error', state: '12345' }, format: :json }

        it { should set_flash[:alert].to 'Доступ запрещен' }

        it 'redirects to sign in path' do
          expect(response).to redirect_to new_user_session_path
        end
      end
    end
  end
end
