FactoryGirl.define do
  factory :admin_role, class: Role do
    name 'admin'
    short_description 'Администратор'
    long_description 'Полные права доступа на все ресурсы'
  end

  factory :***REMOVED***_user_role, class: Role do
    name '***REMOVED***_user'
    short_description 'Пользотель ЛК'
    long_description 'Пользователь ЛК, от которого пользователь ЛК входит в систему'
  end
end
