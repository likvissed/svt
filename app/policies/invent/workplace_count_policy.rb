module Invent
  class WorkplaceCountPolicy < ApplicationPolicy
    def ctrl_access?
      not_for_***REMOVED***_user
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ к указанному отделу.
    # Если роль 'manager': доступ есть.
    def generate_pdf?
      return true if admin?

      if user.role? :***REMOVED***_user
        division_access?
      elsif user.one_of_roles? :manager, :worker, :read_only
        true
      else
        false
      end
    end

    def update?
      return true if admin?

      user.role? :manager
    end

    def create?
      return true if admin?

      user.role? :manager
    end

    def destroy?
      return true if admin?

      user.role? :manager
    end

    class Scope < Scope
      def resolve
        if user.role? :***REMOVED***_user
          scope.joins(:users).where(users: { tn: user.tn })
        else
          scope.all
        end
      end
    end

    protected

    # Есть ли доступ на работу с указанным отделом.
    def division_access?
      user.workplace_counts.pluck(:division).any? { |division| division == record.division }
    end
  end
end
