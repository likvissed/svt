FactoryGirl.define do
  factory :user do
    id_tn 110
    tn 101_101
    phone '50-50'
    division ***REMOVED***
    email nil
    login 'TestLK'
    fullname 'Тест Личного кабинета'
    password 'xxxx1234'
    association :role, factory: :admin_role
  end

  factory :***REMOVED***_user, class: User do
    id_tn 12880
    tn ***REMOVED***
    phone '***REMOVED***'
    division ***REMOVED***
    email 'b***REMOVED***'
    login '***REMOVED***'
    fullname '***REMOVED***'
    association :role, factory: :***REMOVED***_user_role
  end

  factory :invalid_user, class: User do
    tn 123321
  end
end
