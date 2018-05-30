require 'feature_helper'

module Invent
  RSpec.describe WorkplaceType, type: :model do
    it { is_expected.to have_many(:workplaces).dependent(:restrict_with_error) }
  end
end
