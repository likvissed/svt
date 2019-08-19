module Users
  class Create < ApplicationService
    def initialize(user_params)
      @error = {}
      @user_params = user_params
    end

    def run
      create_user
      broadcast_users

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def create_user
      user = User.new(@user_params)
      user.fill_data

      return if user.save

      error[:object] = user.errors
      error[:full_message] = user.errors.full_messages.join('. ')
      raise 'Пользователь не сохранен'
    end
  end
end
