module Warehouse
  class OrderPolicy < ApplicationPolicy
    def new?
      only_for_manager
    end

    def create?
      only_for_manager
    end

    def update?
      only_for_manager
    end

    def execute_in?
      only_for_manager
    end

    def execute_out?
      only_for_manager
    end

    def destroy?
      only_for_manager
    end

    def prepare_to_deliver?
      only_for_manager
    end
  end
end