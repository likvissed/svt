require 'feature_helper'

module Invent
  RSpec.describe Property, type: :model do
    it { is_expected.to have_many(:property_to_types).dependent(:destroy) }
    it { is_expected.to have_many(:types).through(:property_to_types) }
    it { is_expected.to have_many(:property_values).dependent(:destroy) }
    it { is_expected.to have_many(:property_lists).dependent(:destroy) }
    it { is_expected.to have_many(:model_property_lists).dependent(:restrict_with_error) }
  end
end
