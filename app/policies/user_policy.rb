class UserPolicy < ApplicationPolicy
  def ctrl_access?
    return true if admin?

    user.role? :manager
  end
end
