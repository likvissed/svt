require 'feature_helper'

module Invent
  RSpec.describe PropertyToType, type: :model do
    it { is_expected.to belong_to(:type) }
    it { is_expected.to belong_to(:property) }
  end
end
