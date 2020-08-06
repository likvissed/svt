module Warehouse
  class LocationPolicy < Warehouse::ApplicationPolicy
    def ctrl_access?
      not_for_***REMOVED***_user
    end
  end
end
