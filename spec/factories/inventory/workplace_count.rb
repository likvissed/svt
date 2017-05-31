module Inventory
  FactoryGirl.define do
    factory :workplace_count, class: WorkplaceCount do
      status WorkplaceCount.statuses['Разблокирован']
      division { users.empty? ? ***REMOVED*** : users.first.division }

      transient do
        # Массив пользователей, созданный фабрикой user.
        users []
      end

      after(:build) do |workplace_count, evaluator|
        # Если массив users пустой, добавить дефолтного тествого пользователя в качестве ответственного за отдел.
        evaluator.users << build(:user) if evaluator.users.empty?

        evaluator.users.each { |user| workplace_count.users << user }
      end
    end

    factory :active_workplace_count, parent: :workplace_count do
      time_start 10.days.ago
      time_end Time.zone.now + 10.days
    end
  end
end
