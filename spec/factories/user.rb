FactoryGirl.define do
  factory :user do
    tn ***REMOVED***
    info '***REMOVED***'
    association :role, factory: :admin_role
  end

  factory :***REMOVED***_user, class: User do
    tn 999_999
    info 'Пользователь ЛК'
    association :role, factory: :***REMOVED***_user_role
  end
end
