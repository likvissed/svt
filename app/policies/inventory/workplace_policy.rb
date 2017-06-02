module Inventory
  class WorkplacePolicy < ApplicationPolicy
    def load_workplace?
      @user.workplace_counts.pluck(:division).any? { |division| division == @record.workplace_count.division }
    end

    # class Scope < Scope
    #   def resolve
    #     if @user.has_role? :***REMOVED***_user
    #       divisions = @user.workplace_counts.pluck(:division)
    #       scope.where("invent_workplace_count.division IN (#{divisions.empty? ? 'NULL' : divisions.join(', ')})")
    #     else
    #       scope.all
    #     end
    #   end
    # end
  end
end