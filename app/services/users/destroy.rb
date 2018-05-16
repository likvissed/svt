module Users
  class Destroy < ApplicationService
    def initialize(user_id)
      @id = user_id
    end

    def run
      find_user
      destroy_user
      broadcast_users

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def find_user
      @user = User.find(@id)
    end

    def destroy_user
      return if @user.destroy

      @error = @user.errors.full_messages.join('. ')
      raise 'Пользователь не удален'
    end
  end
end
