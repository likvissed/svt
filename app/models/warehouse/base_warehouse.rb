module Warehouse
  class BaseWarehouse < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'warehouse_'
    establish_connection "#{Rails.env}_invent".to_sym
  end
end
