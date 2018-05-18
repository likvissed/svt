class UserPolicy < ApplicationPolicy
  def index?
    return true if admin?

    if user.has_role? :manager
      true
    else
      false
    end
  end
end
