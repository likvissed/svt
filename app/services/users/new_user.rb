module Users
  class NewUser < ApplicationService
    def initialize
      @data = {}
    end

    def run
      init_user
      load_roles

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def init_user
      data[:user] = User.new
    end
  end
end
