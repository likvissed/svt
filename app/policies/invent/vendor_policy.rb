module Invent
  class VendorPolicy < ApplicationPolicy
    def ctrl_access?
      for_worker
    end
  end
end