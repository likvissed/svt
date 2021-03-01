require 'feature_helper'

module Standard
  RSpec.describe Discrepancy, type: :model do
    it { is_expected.to belong_to(:item).class_name('Invent::Item').with_foreign_key('item_id') }
    it { is_expected.to belong_to(:property_value).class_name('Invent::PropertyValue').with_foreign_key('property_value_id').optional }
  end
end
