module ControllerMacros
  include OmniauthMacros

  def sign_in_user
    before do
      @user = create(:user)
      login_with_omniauth
      @request.env['devise.mapping'] = Devise.mappings[:user]
      @request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:open_id_***REMOVED***]

      sign_in @user
    end
  end
end