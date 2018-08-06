class UserIss < Netadmin
  self.table_name = 'netadmin.user_iss'
  self.primary_key = :id_tn

  RECORD_LIMIT = 200
end
