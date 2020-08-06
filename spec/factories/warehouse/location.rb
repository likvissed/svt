module Warehouse
  FactoryBot.define do
    factory :location, class: Location do
      site_id { IssReferenceSite.first.id }
      building_id { IssReferenceSite.first.iss_reference_buildings.first.id }
      room_id { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.first.id }
      comment { nil }
    end
  end
end
