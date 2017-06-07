module Inventory
  class WorkplacePolicy < ApplicationPolicy
    # Есть ли у пользователя доступ на создание/изменение/удаление РМ указанного отдела и не прошло ли разрешенное
    # время редактирования.
    def create?
      division_access? && time_not_passed?
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

    def division_access?
      @user.workplace_counts.pluck(:division).any? { |division| division == @record.workplace_count.division }
    end

    def time_not_passed?
      Time.zone.today.between? @record.workplace_count.time_start, @record.workplace_count.time_end
    end
  end
end