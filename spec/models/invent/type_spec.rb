require 'rails_helper'

module Invent
  RSpec.describe Type, type: :model do
    it { is_expected.to have_many(:items).dependent(:destroy) }
    it { is_expected.to have_many(:property_to_types).dependent(:destroy) }
    it { is_expected.to have_many(:properties).order(:property_order).through(:property_to_types) }
    it { is_expected.to have_many(:models).dependent(:destroy) }
    it { is_expected.to have_many(:vendors).through(:models) }
  end
end
