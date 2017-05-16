module Inventory
  FactoryGirl.define do
    factory :workplace_count, class: WorkplaceCount do
      status WorkplaceCount.statuses['Разблокирован']
      division ***REMOVED***
    end

    factory :active_workplace_count, parent: :workplace_count do
      time_start 10.days.ago
      time_end Time.zone.now + 10.days

      after(:build) do |workplace_count|
        workplace_count.workplace_responsibles << build(
          :workplace_responsible, tn: UserIss.where(dept: workplace_count.division).where('tn < 100000').first.tn
        )
      end
    end
  end
end
