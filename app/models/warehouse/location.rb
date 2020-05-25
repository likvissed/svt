module Warehouse
  class Location < BaseWarehouse
    self.table_name = "#{table_name_prefix}locations"

    belongs_to :iss_reference_site, foreign_key: 'site_id', optional: false
    belongs_to :iss_reference_building, foreign_key: 'building_id', optional: false
    belongs_to :iss_reference_room, foreign_key: 'room_id', optional: false

    has_one :warehouse_item, foreign_key: 'location_id', class_name: 'Warehouse::Item'
  end
end
