require 'feature_helper'

module Invent
  RSpec.describe PropertyList, type: :model do
    it { is_expected.to have_many(:model_property_lists).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:property_values).dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:property).required }
  end
end
