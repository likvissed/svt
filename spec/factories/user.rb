FactoryGirl.define do
  factory :user do
    tn 101_101
    # email nil
    # login 'TestLK'
    fullname 'Тест Личного кабинета'
    password 'xxxx1234'
    association :role, factory: :admin_role
  end

  factory :***REMOVED***_user, class: User do
    tn 999_999
    info 'Пользователь ЛК'
    association :role, factory: :***REMOVED***_user_role
  end
end
