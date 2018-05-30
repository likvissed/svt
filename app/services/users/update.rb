module Users
  class Update < ApplicationService
    def initialize(user_id, user_params)
      @data = {}
      @error = {}
      @user_id = user_id
      @user_params = user_params
    end

    def run
      find_user
      update_user
      broadcast_users

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def find_user
      @user = User.find(@user_id)
    end

    def update_user
      @user.assign_attributes(@user_params)
      @user.fill_data

      return true if @user.save

      error[:object] = @user.errors
      error[:full_message] = @user.errors.full_messages.join('. ')
      raise 'Данные не обновлены'
    end
  end
end
