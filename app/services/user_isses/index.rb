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
                UsersReference.info_users("personnelNo==#{@search_key}&pageSize=100").map { |employee| employee.slice('id', 'personnelNo', 'fullName', 'departmentForAccounting', 'phoneText') }
              else
                UsersReference.info_users("fullName=='*#{CGI.escape(@search_key)}*'&pageSize=100").map { |employee| employee.slice('id', 'personnelNo', 'fullName', 'departmentForAccounting', 'phoneText') }
              end
    end
  end
end
