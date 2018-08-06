module Users
  class Index < ApplicationService
    def initialize(params)
      @data = {}
      @params = params
    end

    def run
      load_users
      limit_records
      prepare_to_render
      load_filters if need_init_filters?

      true
    rescue RuntimeError => e
      Rails.logger.error e.inspect.red
      Rails.logger.error e.backtrace[0..5].inspect

      false
    end

    protected

    def load_users
      data[:recordsTotal] = User.count
      @users = User.all
      run_filters if params[:filters]
    end

    def run_filters
      @users = @users.filter(filtering_params)
    end

    def limit_records
      data[:recordsFiltered] = @users.count
      @users = @users.includes(:role).order(id: :desc).limit(params[:length]).offset(params[:start])
    end

    def prepare_to_render
      data[:data] = @users.as_json(include: :role, methods: %i[current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip online?]).each do |user|
        user['current_sign_in_data'] = "#{user['current_sign_in_at'].strftime('%d-%m-%Y %H:%M:%S')} | #{user['current_sign_in_ip']}" if user['current_sign_in_at']
        user['last_sign_in_data'] = "#{user['last_sign_in_at'].strftime('%d-%m-%Y %H:%M:%S')} | #{user['last_sign_in_ip']}" if user['last_sign_in_at']
      end
    end

    def load_filters
      data[:filters] = {}
      data[:filters][:roles] = Role.all
    end

    def filtering_params
      JSON.parse(params[:filters]).slice('fullname', 'role_id', 'online')
    end
  end
end
