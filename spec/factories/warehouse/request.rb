module Warehouse
  FactoryBot.define do
    factory :request_category_one, class: Request do
      category { 'office_equipment' }
      user_tn { build(:emp_***REMOVED***)['personnelNo'] }
      user_id_tn { build(:emp_***REMOVED***)['id'] }
      user_fio { build(:emp_***REMOVED***)['fullName'] }
      user_dept { build(:emp_***REMOVED***)['departmentForAccounting'] }
      user_phone { build(:emp_***REMOVED***)['phoneText'] }
      number_***REMOVED*** { 123 }
      number_***REMOVED*** { 321 }
      executor_fio { build(:emp_***REMOVED***)['fullName'] }
      executor_tn { build(:emp_***REMOVED***)['personnelNo'] }
      comment { nil }
      status { 'new' }
      recommendation_json { nil }
      ssd_id { 'f11391dd-5640-11ec-8064-00505691df09' }

      request_items { [create(:request_item)] }
    end

    factory :request_category_two, class: Request do
      category { 'printing' }
      user_tn { build(:emp_***REMOVED***)['personnelNo'] }
      user_id_tn { build(:emp_***REMOVED***)['id'] }
      user_fio { build(:emp_***REMOVED***)['fullName'] }
      user_dept { build(:emp_***REMOVED***)['departmentForAccounting'] }
      user_phone { build(:emp_***REMOVED***)['phoneText'] }
      number_***REMOVED*** { 123 }
      number_***REMOVED*** { 321 }
      executor_fio { build(:emp_***REMOVED***)['fullName'] }
      executor_tn { build(:emp_***REMOVED***)['personnelNo'] }
      comment { nil }
      status { 'new' }
    end
  end
end
