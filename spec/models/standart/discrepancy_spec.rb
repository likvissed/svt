require 'rails_helper'

module Standart
  RSpec.describe Discrepancy, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::InvItem') }
    it { is_expected.to belong_to(:inv_property_value).class_name('Invent::InvPropertyValue') }
  end
end
