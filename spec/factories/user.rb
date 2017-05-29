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
    id_tn 1
    tn 999_999
    phone '50-49'
    fullname 'Пользователь ЛК'
    association :role, factory: :***REMOVED***_user_role
  end
end
