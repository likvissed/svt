class AuthorizeStrategy < Warden::Strategies::Base
  def valid?
    params['code'].present?
  end

  def authenticate!
    token = Authorize.get_token(params[:code])
    return fail!('Неверный токен') unless token['access_token']

    user_info = Authorize.get_user(token['access_token'])
    return fail!('Пользователь не найден') unless user_info['tn']

    user = User.find_by(tn: user_info['tn'])
    return fail!('Не удалось выполнить вход в систему') if user.nil?

    session['user'] = user_info
    session['session_id'] = token['access_token']
    session['refresh_token'] = token['refresh_token']

    success!(user)
  end
end
