module Warehouse
  class AttachmentOrderPolicy < Warehouse::ApplicationPolicy
    def create?
      for_worker
    end
  end
end
