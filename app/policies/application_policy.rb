class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Есть ли доступ к контроллерам (за исключение :***REMOVED***_invents)
  def authorization?
    !user.has_role? :***REMOVED***_user
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
