class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data

  def current_user
    @current_user
  end
end