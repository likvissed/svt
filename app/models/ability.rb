class Ability
  include CanCan::Ability

  def initialize(user)
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :***REMOVED***_user
      can :manage, :***REMOVED***_invent
    else
      cannot :manage, :all
    end
  end
end
