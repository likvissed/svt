require 'rails_helper'

module Warehouse
  RSpec.describe Location, type: :model do
    it { is_expected.to have_many(:operations).with_foreign_key(:warehouse_location_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:items).through(:operations) }
  end
end
