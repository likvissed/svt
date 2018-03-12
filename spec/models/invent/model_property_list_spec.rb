require 'feature_helper'

module Invent
  RSpec.describe ModelPropertyList, type: :model do
    it { is_expected.to belong_to(:model) }
    it { is_expected.to belong_to(:property) }
    it { is_expected.to belong_to(:property_list) }
  end
end
