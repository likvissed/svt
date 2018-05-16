module Users
  class Edit < ApplicationService
    def initialize(user_id)
      @data = {}
      @id = user_id
    end

    def run
      find_user
      load_roles

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def find_user
      data[:user] = User.find(@id)
    end
  end
end
