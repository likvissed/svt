module Warehouse
  class RequestPolicy < Warehouse::ApplicationPolicy
    def index?
      for_worker
    end
  end
end
