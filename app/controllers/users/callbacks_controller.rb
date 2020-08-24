class Users::CallbacksController < DeviseController
  skip_before_action :verify_authenticity_token
  def registration_user
    session[:state] ||= Digest::MD5.hexdigest(rand.to_s)

    redirect_to AuthCenter.authorize_url(session[:state])
  end

  def authorize_user
    return authorize_error if params[:error] || session[:state] != params[:state]
    session.delete(:state)

    sign_in_and_redirect warden.authenticate!(:authorize_strategy)
    set_flash_message(:notice, :success)
  end

  def authorize_error
    set_flash_message(:alert, :failure)
    redirect_to new_user_session_path
  end
end
