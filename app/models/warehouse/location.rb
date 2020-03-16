module Warehouse
  class Location < BaseWarehouse
    self.table_name = "#{table_name_prefix}locations"

    belongs_to :iss_reference_site, foreign_key: 'site_id', optional: true
    belongs_to :iss_reference_building, foreign_key: 'building_id', optional: true
    belongs_to :iss_reference_room, foreign_key: 'room_id', optional: true

    has_one :warehouse_item, foreign_key: 'location_id', class_name: 'Warehouse::Item', dependent: :destroy

    validates :site_id, presence: true
    validates :building_id, presence: true
    validates :room_id, presence: true
  end
end
