module Invent
  class Sign < BaseInvent
    self.primary_key = :sign_id
    self.table_name = "#{table_name_prefix}signs"

    has_many :bindings, class_name: 'BindingSign', foreign_key: 'invent_sign_id'
  end
end
