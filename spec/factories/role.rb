FactoryBot.define do
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

  factory :manager_role, class: Role do
    name 'manager'
    short_description 'Менеджер'
    long_description 'Пользователь с расширенными правами'
  end

  factory :read_only_role, class: Role do
    name 'read_only'
    short_description 'Гость'
    long_description 'Доступ только на чтение'
  end

  factory :worker_role, class: Role do
    name 'worker'
    short_description 'Работник'
    long_description 'Доступ на основные действия с моделями'
  end
end
