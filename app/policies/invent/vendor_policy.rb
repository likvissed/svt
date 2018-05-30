module Invent
  class VendorPolicy < ApplicationPolicy
    def index?
      for_worker
    end
  end
end