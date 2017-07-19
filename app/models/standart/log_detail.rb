module Standart
  class LogDetail < BaseStandart
    belongs_to :log
    belongs_to :inv_property, class_name: 'Invent::InvProperty', foreign_key: 'property_id'
  end
end
