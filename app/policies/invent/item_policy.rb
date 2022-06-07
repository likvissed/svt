module Invent
  class ItemPolicy < ApplicationPolicy
    def ctrl_access?
      not_for_***REMOVED***_user
    end

    def update?
      for_worker
    end

    def destroy?
      for_worker
    end

    def to_stock?
      for_worker
    end

    def permitted_attributes
      [
        :item_id,
        :parent_id,
        :model_id,
        :item_model,
        :location,
        :invent_num,
        :serial_num,
        :priority,
        binders_attributes: %i[
          id
          description
          sign_id
          invent_item_id
          warehouse_item_id
          _destroy
        ],
        property_values_attributes: %i[id property_id item_id property_list_id value _destroy]
      ]
    end
  end
end
