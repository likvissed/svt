module Invent
  class ModelPolicy < ApplicationPolicy
    def index?
      for_worker
    end
  end
end