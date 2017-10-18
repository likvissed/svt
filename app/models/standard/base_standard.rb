module Standard
  class BaseStandard < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'standard_'
  end
end
