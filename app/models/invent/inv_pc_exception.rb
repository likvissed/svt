module Invent
  class InvPcException < BaseInvent
    self.table_name = "#{table_name_prefix}pc_exceptions"
  end
end
