module Warehouse
  class ItemPolicy < ApplicationPolicy
    def destroy?
      for_worker
    end
  end
end