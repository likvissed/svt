module Invent
  class ModelPolicy < ApplicationPolicy
    def ctrl_access?
      for_worker
    end
  end
end