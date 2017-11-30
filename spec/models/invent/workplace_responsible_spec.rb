require 'rails_helper'

module Invent
  RSpec.describe WorkplaceResponsible, type: :model do
    it { is_expected.to belong_to(:workplace_count) }
    it { is_expected.to belong_to(:user) }
  end
end
