class Warehouse::ApplicationPolicy < ApplicationPolicy
  def ctrl_access?
    not_for_***REMOVED***_user
  end

  def destroy?
    for_worker
  end
end