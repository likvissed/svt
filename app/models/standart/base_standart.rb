module Standart
  class BaseStandart < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'standart_'
  end
end
