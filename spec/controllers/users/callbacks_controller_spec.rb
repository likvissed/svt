require 'rails_helper'

module Users
  RSpec.describe CallbacksController, type: :controller do
    describe 'GET #open_id_***REMOVED***' do
      context 'when attributes is valid' do
        sign_in_user

        before { get :open_id_***REMOVED*** }

        it 'assigns the user to @user' do
          expect(assigns(:user)).to eq @user
        end

        it 'redirects to authenticated root path' do
          expect(response).to redirect_to authenticated_root_path
        end

        it 'must have open_id params' do
          expect(@request.env['omniauth.auth'].info.keys).to include('fullname', 'tn')
        end

        it { should set_flash[:notice].to 'Вход в систему выполнен' }
      end

      context 'when attributes is invalid' do
        sign_in_user({ fullname: '' })

        before { get :open_id_***REMOVED*** }

        context 'and when tn is set' do
          context 'and when fullname is not set' do
            it 'redirects to sign in path' do
              expect(response).to redirect_to new_user_session_path
            end

            it { should set_flash[:alert].to 'Ошибка авторизации. Обратитесь к администратору по тел. ***REMOVED***' }
          end
        end

        context 'and when tn is not set' do
          it 'redirects to sign in path' do
            expect(response).to redirect_to new_user_session_path
          end
        end
      end
    end
  end
end
