require 'rails_helper'

module Invent
  RSpec.describe Model, type: :model do
    it { is_expected.to have_many(:model_property_lists).dependent(:destroy) }
    it { is_expected.to have_many(:items).dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:vendor) }
    it { is_expected.to belong_to(:type) }
  end
end
