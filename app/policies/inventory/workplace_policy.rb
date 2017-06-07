module Inventory
  class WorkplacePolicy < ApplicationPolicy
    # Есть ли у пользователя доступ на создание РМ указанного отдела.
    def create?
      division_access? && allowed_time?
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на редактирование РМ указанного отдела.
    # Иначе: доступ есть.
    def edit?
      @user.has_role?(:***REMOVED***_user) ? division_access? && allowed_time? && !confirmed? : true
    end

    # Если роль '***REMOVED***_user': есть ли у пользователя доступ на редактирование РМ указанного отдела.
    # Если роль не '***REMOVED***_user', но ответственный за отдел (администратор и ответственный за отдел в одном лице): доступ
    #   есть
    # Для остальных: можно обновлять данные только по истечении разрешенного пользователям ЛК времени редактирования.
    def update?
      if @user.has_role?(:***REMOVED***_user)
        division_access? && allowed_time? && !confirmed?
      elsif division_access?
        true
      else
        !allowed_time?
      end
    end

    class Scope < Scope
      def resolve
        if @user.has_role? :***REMOVED***_user
          divisions = @user.workplace_counts.pluck(:division)
          scope.where("invent_workplace_count.division IN (#{divisions.empty? ? 'NULL' : divisions.join(', ')})")
        else
          scope.all
        end
      end
    end

    private

    # Есть ли доступ на работу с РМ указанного отдела.
    def division_access?
      @user.workplace_counts.pluck(:division).any? { |division| division == @record.workplace_count.division }
    end

    # Не прошло ли разрешенное время редактирования.
    def allowed_time?
      Time.zone.today.between? @record.workplace_count.time_start, @record.workplace_count.time_end
    end

    # Подтверждено ли рабочее место.
    def confirmed?
      @record.status == 'confirmed'
    end
  end
end