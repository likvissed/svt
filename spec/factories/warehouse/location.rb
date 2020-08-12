module Warehouse
  FactoryBot.define do
    factory :location, class: Location do
      site_id { IssReferenceSite.first.id }
      building_id { IssReferenceSite.first.iss_reference_buildings.first.id }
      room_id { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.first.id }
      comment { nil }
    end

    factory :other_location, class: Location do
      site_id { IssReferenceSite.last.id }
      building_id { IssReferenceSite.last.iss_reference_buildings.last.id }
      room_id { IssReferenceSite.last.iss_reference_buildings.last.iss_reference_rooms.last.id }
      comment { '123' }
    end
  end
end
