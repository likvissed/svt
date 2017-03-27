class Netadmin < ApplicationRecord
  self.abstract_class = true
  establish_connection :netadmin
end