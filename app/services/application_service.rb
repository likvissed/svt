class ApplicationService
  include Pundit
  include ActiveModel::Validations
  include Broadcast

  attr_reader :data, :current_user, :error, :params

  def initialize(*args)
    @data = {}
    @error = {}
  end

  def load_roles
    data[:roles] = Role.all
  end

  def need_init_filters?
    params[:init_filters] == 'true'
  end
end
