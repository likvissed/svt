require 'feature_helper'

module Warehouse
  RSpec.describe Location, type: :model do
    it { is_expected.to have_many(:operations).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:items).through(:operations) }
  end
end
