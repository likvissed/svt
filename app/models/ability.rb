class Ability
  include CanCan::Ability

  def initialize(user)
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :***REMOVED***_user
      can :manage, :***REMOVED***_invent
      # can :init_properties, :***REMOVED***_invent
      # can :show_division_data, :***REMOVED***_invent, {  }
      # can :pc_config_from_audit, :***REMOVED***_invent
      # can :create_workplace, :***REMOVED***_invent
    else
      cannot :manage, :all
    end
  end
end
