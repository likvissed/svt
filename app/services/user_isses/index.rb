module UserIsses
  class Index < ApplicationService
    def initialize(search_key)
      @search_key = search_key
    end

    def run
      find_users

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def find_users
      @data = if @search_key.is_integer?
                UserIss.select(:id_tn, :tn, :fio, :dept).where(tn: @search_key).limit(200)
              else
                UserIss.select(:id_tn, :tn, :fio, :dept).where('fio LIKE ?', "%#{@search_key}%").limit(200)
              end
    end
  end
end
