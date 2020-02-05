class FailureStrategy < Devise::FailureApp
  def route(scope)
    if params['code'].present?
      :new_user_session_url
    else
      :users_callbacks_registration_user_url
    end
  end
end
