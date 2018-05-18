module Warehouse
  class ItemPolicy < ApplicationPolicy
    def destroy?
      only_for_manager
    end
  end
end