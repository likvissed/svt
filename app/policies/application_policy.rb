class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Пользователям с ролью ***REMOVED***_user доступ запрещен
  def authorization?
    !user.role? :***REMOVED***_user
  end

  def admin?
    user.role? :admin
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

  protected

  def only_for_manager
    return true if admin?

    user.role? :manager
  end
end
