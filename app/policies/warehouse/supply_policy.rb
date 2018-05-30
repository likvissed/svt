module Warehouse
  class SupplyPolicy < ApplicationPolicy
    def new?
      for_worker
    end

    def create?
      for_worker
    end

    def edit?
      for_worker
    end

    def update?
      for_worker
    end

    def destroy?
      for_worker
    end
  end
end
