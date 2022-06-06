module Warehouse
  class ItemPolicy < Warehouse::ApplicationPolicy
    def ctrl_access?
      not_for_***REMOVED***_user
    end

    def create?
      for_worker
    end

    def edit?
      for_worker
    end

    def update?
      for_worker
    end

    def permitted_attributes
      [
        :id,
        :invent_item_id,
        :invent_type_id,
        :invent_model_id,
        :arm_stock_id,
        :warehouse_type,
        :item_type,
        :item_model,
        :barcode,
        :status,
        :count,
        :count_reserved,
        :invent_num_start,
        :invent_num_end,
        :location_id,
        :create_time,
        :modify_time,
        location: %i[
          id
          site_id
          building_id
          room_id
          comment
        ],
        binders_attributes: %i[
          id
          description
          sign_id
          warehouse_item_id
          _destroy
        ],
        property_values_attributes: %i[
          id
          warehouse_item_id
          property_id
          value
          _destroy
        ]
      ]
    end
  end
end
