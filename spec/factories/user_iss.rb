FactoryBot.define do
  factory :user_iss do
    tn { 101_101 }
    dept { ***REMOVED*** }
    fio { 'Тест Личного кабинета' }
    room { '2-40' }
    tel { '54-26' }
    wname { '' }
    email { '' }
    comment { '' }
    duty { 'Тестер личного кабинета' }
    status { '' }
    datereg { 5.years.ago }
    duty_code { 0 }
    fio_initials { 'Тест Л.к.' }
    category { 0 }
    id_tn { 110 }
    dept_kadr { 0 }
    decret { false }
  end

  factory :***REMOVED***_user_iss, class: UserIss do
    tn { ***REMOVED*** }
    dept { ***REMOVED*** }
    fio { '***REMOVED***' }
    room { '3а-321а' }
    tel { '***REMOVED***' }
    wname { '' }
    email { '' }
    comment { '' }
    duty { 'инженер-программист 3 категории' }
    status { 'changed' }
    datereg { 5.years.ago }
    duty_code { 0 }
    fio_initials { '***REMOVED*** Р.Ф.' }
    category { 4 }
    id_tn { ***REMOVED*** }
    dept_kadr { ***REMOVED*** }
    decret { false }
  end
end
