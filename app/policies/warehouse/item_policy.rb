module Warehouse
  class ItemPolicy < Warehouse::ApplicationPolicy
    def ctrl_access?
      not_for_***REMOVED***_user
    end

    def edit?
      record.new?
    end

    def update?
      for_worker if record.new?
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
          name
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
