module Inventory
  FactoryGirl.define do
    factory :iss_room, class: IssReferenceRoom do
      iss_reference_building { IssReferenceBuilding.first }
      sequence(:name) { |i| "test_room_#{i}" }
    end
  end
end
