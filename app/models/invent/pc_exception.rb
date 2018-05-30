module Invent
  class PcException < BaseInvent
    self.table_name = "#{table_name_prefix}pc_exceptions"
  end
end
