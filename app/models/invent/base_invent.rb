module Invent
  class BaseInvent < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'invent_'
    establish_connection "#{Rails.env}_invent".to_sym
  end
end
