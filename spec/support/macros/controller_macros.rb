require_relative './omniauth_macros'

module ControllerMacros
  include OmniauthMacros

  def sign_in_user(**params)
    before do
      allow(UsersReference).to receive(:info_users)
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      allow_any_instance_of(UserIssByIdTnValidator).to receive(:validate_each)

      @user = create(:user, params)
      login_with_omniauth

      @request.env['devise.mapping'] = Devise.mappings[:user]
      @request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:open_id_***REMOVED***]

      sign_in @user
    end
  end

  def sign_in_through_***REMOVED***_user
    before do
      @***REMOVED***_user = create(:user)
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in @***REMOVED***_user
    end
  end
end
