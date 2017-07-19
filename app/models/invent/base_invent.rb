module Invent
  class BaseInvent < ApplicationRecord
    self.abstract_class = true
    establish_connection "#{Rails.env}_invent".to_sym
  end
end
