module Warehouse
  class LocationPolicy < Warehouse::ApplicationPolicy
    def ctrl_access?
      # Для фильтров корпусов и комнат на странице РМ
      if user.role? :***REMOVED***_user
        user.workplace_counts.any?
      else
        true
      end
    end
  end
end
