module Inventory
  class Invent < ApplicationRecord
    self.abstract_class = true
    establish_connection "#{Rails.env}_invent".to_sym
  end
end