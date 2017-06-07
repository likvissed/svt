module Inventory
  class WorkplacePolicy < ApplicationPolicy
    # Есть ли у пользователя доступ на создание РМ указанного отдела.
    def create?
      division_access? && time_not_passed?
    end

    # Есть ли у пользователя доступ на редактирование РМ указанного отдела. Пользователь с ролью, отличной от :***REMOVED***_user,
    # могут просматривать РМ в любое время.
    def edit?
      @user.has_role?(:***REMOVED***_user) ? division_access? && time_not_passed? && !confirmed? : true
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
    def time_not_passed?
      Time.zone.today.between? @record.workplace_count.time_start, @record.workplace_count.time_end
    end

    # Подтверждено ли рабочее место.
    def confirmed?
      @record.status == 'confirmed'
    end
  end
end