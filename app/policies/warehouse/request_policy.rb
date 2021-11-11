module Warehouse
  class RequestPolicy < Warehouse::ApplicationPolicy
    def index?
      for_worker
    end

    def edit?
      not_for_***REMOVED***_user
    end

    def send_for_analysis?
      for_manager
    end

    def assign_new_executor?
      for_manager
    end

    def close?
      return true if admin?

      user.one_of_roles? :manager, :worker
    end

    def send_for_confirm?
      for_manager
    end

    class Scope < Scope
      def resolve
        if user.role? :worker
          scope.where(executor_fio: user.fullname)
        else
          scope.all
        end
      end
    end
  end
end
