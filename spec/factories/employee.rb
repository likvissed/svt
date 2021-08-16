FactoryBot.define do
  factory :emp_empty, class: Hash do
    nil
  end

  factory :emp_***REMOVED***, class: Hash do
    positionId { 2273 }
    id { ***REMOVED*** }
    fullName { '***REMOVED***' }
    personnelNo { ***REMOVED*** }
    departmentId { 10_134 }
    departmentForAccounting { ***REMOVED*** }
    departmentForDocuments { '***REMOVED***' }
    deptForDocs { ***REMOVED*** }
    professionCode { 24_907 }
    professionForAccounting { 'НАЧАЛЬНИК СЕКТОРА' }
    professionForDocuments { 'НАЧАЛЬНИК СЕКТОРА РЕМОНТА ПЕРСОНАЛЬНЫХ КОМПЬЮТЕРОВ' }
    phone { ['***REMOVED***'] }
    mobilePhone { [] }
    email { ['***REMOVED***'] }
    phoneText { '***REMOVED***' }
    emailText { '***REMOVED***' }
    position { '2-237' }

    initialize_with { attributes.stringify_keys }
  end

  factory :emp_***REMOVED***, class: Hash do
    id { 72 }
    fullName { '***REMOVED***' }
    personnelNo { 24_031 }
    departmentId { 10_134 }
    departmentForAccounting { ***REMOVED*** }
    professionForAccounting { 'ВЕДУЩИЙ ИНЖЕНЕР-ЭЛЕКТРОНИК' }
    professionForDocuments { 'ВЕДУЩИЙ ИНЖЕНЕР-ЭЛЕКТРОНИК' }

    initialize_with { attributes.stringify_keys }
  end

  factory :emp_***REMOVED***, class: Hash do
    id { 5336 }
    fullName { '***REMOVED***' }
    personnelNo { 24_079 }
    departmentId { 10_134 }
    departmentForAccounting { ***REMOVED*** }
    professionForAccounting { 'ВЕДУЩИЙ ИНЖЕНЕР' }
    professionForDocuments { 'ВЕДУЩИЙ ИНЖЕНЕР' }
    phoneText { '39-45' }

    initialize_with { attributes.stringify_keys }
  end

  factory :emp_***REMOVED***, class: Hash do
    id { 15_907 }
    fullName { '***REMOVED***' }
    personnelNo { 12_321 }
    departmentId { 10_129 }
    departmentForAccounting { ***REMOVED*** }
    professionForAccounting { 'МАСТЕР' }
    professionForDocuments { 'МАСТЕР' }
    mobilePhone { [] }
    email { [] }

    initialize_with { attributes.stringify_keys }
  end

  factory :emp_***REMOVED***, class: Hash do
    lastName { '***REMOVED***' }
    firstName { '***REMOVED***' }
    middleName { '***REMOVED***' }
    positionId { 7790 }
    id { ***REMOVED*** }
    sex { 'Ж' }
    fullName { '***REMOVED***' }
    personnelNo { ***REMOVED*** }
    departmentId { 10_134 }
    departmentForAccounting { ***REMOVED*** }
    departmentForDocuments { '***REMOVED***' }
    deptForDocs { '***REMOVED***' }
    professionCode { 22_446 }
    professionForAccounting { 'ИНЖЕНЕР' }
    professionForDocuments { 'ИНЖЕНЕР' }
    inVacation { false }
    employeeStatusId { 0 }
    employeeStatus { 'Основной' }
    struct { '***REMOVED***' }
    computerName { 'n769566' }
    phone { ['***REMOVED***'] }
    mobilePhone { [] }
    email { ['***REMOVED***'] }
    phoneText { '***REMOVED***' }
    emailText { '***REMOVED***' }
    position { '3А-320' }
    vacation { 'Декретный отпуск' }
    vacationFrom { '2222-11-11' }
    vacationTo { '2222-02-22' }

    initialize_with { attributes.stringify_keys }
  end

  factory :emp_***REMOVED***, class: Hash do
    lastName { '***REMOVED***' }
    firstName { '***REMOVED***' }
    middleName { '***REMOVED***' }
    positionId { 6295 }
    id { ***REMOVED*** }
    sex { 'М' }
    fullName { '***REMOVED***' }
    personnelNo { ***REMOVED*** }
    departmentId { 10_134 }
    departmentForAccounting { ***REMOVED*** }
    departmentForDocuments { '***REMOVED***' }
    deptForDocs { '***REMOVED***' }
    professionCode { 228_242 }
    professionForAccounting { 'ИНЖЕНЕР-ПРОГРАММИСТ 2 КАТЕГОРИИ' }
    professionForDocuments { 'ИНЖЕНЕР-ПРОГРАММИСТ 2 КАТЕГОРИИ' }
    inVacation { false }
    employeeStatusId { 0 }
    employeeStatus { 'Основной' }
    struct { '***REMOVED***' }
    computerName { '.........' }
    phone { ['***REMOVED***'] }
    mobilePhone { [] }
    email { ['b***REMOVED***'] }
    phoneText { '***REMOVED***' }
    emailText { 'b***REMOVED***' }
    position { '3а-321а' }

    initialize_with { attributes.stringify_keys }
  end
end
