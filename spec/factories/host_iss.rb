FactoryBot.define do
  factory :host_iss, class: Hash do
    # Здесь показаны не все параметры таблицы 'hosts'.
    id { '768707' }
    ip { '***REMOVED***' }
    mac { '***REMOVED***' }
    tn { 3737 }
    user { '***REMOVED***' }
    division { '***REMOVED***' }
    flag_set { 'inet_access,ad_member,auto_auth' }

    initialize_with { attributes }
  end
end
