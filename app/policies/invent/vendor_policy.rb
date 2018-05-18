module Invent
  class VendorPolicy < ApplicationPolicy
    def index?
      only_for_manager
    end
  end
end