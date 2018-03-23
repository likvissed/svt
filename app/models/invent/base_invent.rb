module Invent
  class BaseInvent < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'invent_'
    establish_connection "#{Rails.env}_invent".to_sym

    def self.by_type_id(type_id)
      return all if type_id.to_i.zero?
      where(type_id: type_id)
    end
  end
end
