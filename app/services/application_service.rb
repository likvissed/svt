class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data, :current_user
end
