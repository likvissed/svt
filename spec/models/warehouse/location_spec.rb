require 'feature_helper'

module Warehouse
  RSpec.describe Location, type: :model do
    it { is_expected.to belong_to(:iss_reference_site).with_foreign_key('site_id') }
    it { is_expected.to belong_to(:iss_reference_building).with_foreign_key('building_id') }
    it { is_expected.to belong_to(:iss_reference_room).with_foreign_key('room_id') }
    it { is_expected.to have_one(:warehouse_item).with_foreign_key('location_id').class_name('Warehouse::Item').dependent(:destroy) }
    it { is_expected.to validate_presence_of(:site_id) }
    it { is_expected.to validate_presence_of(:building_id) }
    it { is_expected.to validate_presence_of(:room_id) }
  end
end
