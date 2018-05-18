module Invent
  class ModelPolicy < ApplicationPolicy
    def index?
      only_for_manager
    end
  end
end