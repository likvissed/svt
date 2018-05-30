class UserPolicy < ApplicationPolicy
  def index?
    return true if admin?

    user.role? :manager
  end
end
