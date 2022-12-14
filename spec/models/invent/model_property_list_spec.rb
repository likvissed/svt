require 'feature_helper'

module Invent
  RSpec.describe ModelPropertyList, type: :model do
    it { is_expected.to belong_to(:model).required }
    it { is_expected.to belong_to(:property).required }
    it { is_expected.to belong_to(:property_list).required }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:property) }
    it { is_expected.to validate_presence_of(:property_list) }
  end
end
