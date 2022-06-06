module Invent
  class Sign < BaseInvent
    self.primary_key = :sign_id
    self.table_name = "#{table_name_prefix}signs"

    #TODO: has_many invent_bindings and warehouse_bindings
  end
end
