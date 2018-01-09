FactoryBot.define do
  factory :user do
    id_tn 110
    tn 101_101
    phone '50-50'
    division ***REMOVED***
    email nil
    login 'TestLK'
    fullname 'Тест Личного кабинета'
    password 'xxxx1234'

    after(:build) do |user, ev|
      unless ev.role
        user.role = Role.find_by(name: :admin) || create(:admin_role)
      end
    end
  end

  factory :***REMOVED***_user, class: User do
    id_tn ***REMOVED***
    tn ***REMOVED***
    phone '***REMOVED***'
    division ***REMOVED***
    email 'b***REMOVED***'
    login '***REMOVED***'
    fullname '***REMOVED***'

    after(:build) do |user, ev|
      unless ev.role
        user.role = Role.find_by(name: :***REMOVED***_user) || create(:***REMOVED***_user_role)
      end
    end
  end

  factory :***REMOVED***_user, class: User do
    id_tn 5336
    tn 24_079
    phone '39-45'
    division ***REMOVED***
    email 'v***REMOVED***@***REMOVED***.ru'
    login '***REMOVED***'
    fullname '***REMOVED***'
    association :role, factory: :manager_role

    after(:build) do |user, ev|
      unless ev.role
        user.role = Role.find_by(name: :manager) || create(:manager_role)
      end
    end
  end

  factory :invalid_user, class: User do
    id_tn 111_222
    tn 123_321
  end
end
