module Warehouse
  class SupplyPolicy < ApplicationPolicy
    def new?
      only_for_manager
    end

    def create?
      only_for_manager
    end

    def edit?
      only_for_manager
    end

    def update?
      only_for_manager
    end

    def destroy?
      only_for_manager
    end
  end
end
