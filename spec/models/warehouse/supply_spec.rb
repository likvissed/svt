require 'rails_helper'

module Warehouse
  RSpec.describe Supply, type: :model do
    it { is_expected.to have_many(:operations) }
  end
end
