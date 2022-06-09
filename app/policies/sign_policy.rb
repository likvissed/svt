class SignPolicy < ApplicationPolicy
  def ctrl_access?
    for_worker
  end
end
