require 'rails_helper'

module Invent
  RSpec.describe Vendor, type: :model do
    it { is_expected.to have_many(:models).dependent(:destroy) }
    it { is_expected.to have_many(:types).through(:models) }
  end
end
