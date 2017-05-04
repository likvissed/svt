class SMSServer < ApplicationRecord
  self.abstract_class = true
  establish_connection :smssvr

  # establish_connection(
  #   adapter:  'sqlserver',
  #   username: 'invent_user',
  #   password: 'hwInvent0ry',
  #   host:     'smssvr')
end
