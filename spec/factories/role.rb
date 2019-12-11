FactoryBot.define do
  factory :admin_role, class: Role do
    name { 'admin' }
    short_description { 'Администратор' }
    long_description { 'Полные права доступа' }
  end

  factory :***REMOVED***_user_role, class: Role do
    name { '***REMOVED***_user' }
    short_description { 'Ответственный за ВТ' }
    long_description { 'Доступ на создание/редактирование РМ через ЛК и СВТ (только если РМ не подтверждено)' }
  end

  factory :manager_role, class: Role do
    name { 'manager' }
    short_description { 'Менеджер' }
    long_description { 'Пользователь с расширенными правами' }
  end

  factory :read_only_role, class: Role do
    name { 'read_only' }
    short_description { 'Гость' }
    long_description { 'Доступ только на чтение' }
  end

  factory :worker_role, class: Role do
    name { 'worker' }
    short_description { 'Работник' }
    long_description { 'Работник сектора ремонта ВТ с ограниченными правами' }
  end
end
