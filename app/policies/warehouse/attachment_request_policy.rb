module Warehouse
  class AttachmentRequestPolicy < Warehouse::ApplicationPolicy
    def create?
      for_worker
    end
  end
end
