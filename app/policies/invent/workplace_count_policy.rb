module Invent
  class WorkplaceCountPolicy < ApplicationPolicy
    # Если роль '***REMOVED***_user': есть ли у пользователя доступ к указанному отделу.
    # Если роль 'manager': доступ есть.
    def generate_pdf?
      return true if admin?

      if @user.role? :***REMOVED***_user
        division_access?
      elsif @user.one_of_roles? :manager, :worker, :read_only
        true
      else
        false
      end
    end

    protected

    # Есть ли доступ на работу с указанным отделом.
    def division_access?
      @user.workplace_counts.pluck(:division).any? { |division| division == @record.division }
    end
  end
end
