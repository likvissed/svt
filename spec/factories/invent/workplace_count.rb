module Invent
  FactoryGirl.define do
    factory :workplace_count, class: WorkplaceCount do
      division { users.empty? ? ***REMOVED*** : users.first.division }
      users []

      trait :default_user do
        after(:build) do |workplace_count, evaluator|
          # Если массив users пустой, добавить дефолтного тествого пользователя в качестве ответственного за отдел.
          workplace_count.users << build(:user) if workplace_count.users.empty?
        end
      end
    end

    factory :active_workplace_count, parent: :workplace_count do
      time_start 10.days.ago
      time_end Time.zone.now + 10.days
    end

    factory :inactive_workplace_count, parent: :workplace_count do
      time_start 10.days.ago
      time_end 5.days.ago
    end
  end
end
