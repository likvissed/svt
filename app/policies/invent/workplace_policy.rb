module Invent
  class WorkplacePolicy < ApplicationPolicy
    def new?
      return true if admin?

      if user.role? :***REMOVED***_user
        division_access? && allowed_time?
      elsif user.one_of_roles? :manager, :worker
        true
      else
        false
      end
    end

    # Есть ли у пользователя доступ на создание РМ указанного отдела.
    def create?
      return true if admin?

      if user.role? :***REMOVED***_user
        division_access? && allowed_time?
      elsif user.one_of_roles? :manager, :worker
        true
      else
        false
      end
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на редактирование РМ указанного отдела.
    # Если роль 'manager': доступ есть
    def edit?
      return true if admin?

      if user.role? :***REMOVED***_user
        division_access? && allowed_time?
      elsif user.one_of_roles? :manager, :worker, :read_only
        true
      else
        false
      end
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на редактирование РМ указанного отдела.
    # Если роль 'manager': доступ есть
    def update?
      return true if admin?

      if user.role? :***REMOVED***_user
        division_access? && allowed_time?
      elsif user.one_of_roles? :manager, :worker
        true
      else
        false
      end
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на удаление РМ указанного отдела.
    # Если роле не '***REMOVED***_user', но ответственный за отдел + доступ по времени открыт: доступ есть
    # def destroy?
    #   return true if admin?

    #   if user.role? :***REMOVED***_user
    #     division_access? && allowed_time? && !confirmed?
    #   elsif user.role? :manager
    #     true
    #   else
    #     false
    #   end
    # end

    def destroy?
      return true if admin?

      user.one_of_roles? :manager, :worker
    end

    def hard_destroy?
      return true if admin?

      user.one_of_roles? :manager, :worker
    end

    class Scope < Scope
      def resolve
        if user.role? :***REMOVED***_user
          divisions = user.workplace_counts.pluck(:division)
          scope.where("invent_workplace_count.division IN (#{divisions.empty? ? 'NULL' : divisions.join(', ')})")
        else
          scope.all
        end
      end
    end

    private

    # Есть ли доступ на работу с РМ указанного отдела.
    def division_access?
      @user.workplace_counts.pluck(:division).any? { |division| division == record.workplace_count.division }
    end

    # Не прошло ли разрешенное время редактирования.
    def allowed_time?
      Time.zone.today.between? record.workplace_count.time_start, record.workplace_count.time_end
    end

    # Подтверждено ли рабочее место.
    def confirmed?
      @record.status == 'confirmed'
    end
  end
end
