module Standard
  class LogDetail < BaseStandard
    belongs_to :log
    belongs_to :property, class_name: 'Invent::Property', foreign_key: 'property_id'
  end
end
