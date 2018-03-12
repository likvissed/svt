require 'feature_helper'

module Standard
  RSpec.describe Discrepancy, type: :model do
    it { is_expected.to belong_to(:item).class_name('Invent::Item') }
    it { is_expected.to belong_to(:property_value).class_name('Invent::PropertyValue') }
  end
end
