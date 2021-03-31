require 'feature_helper'

module Warehouse
  RSpec.describe Location, type: :model do
    it { is_expected.to belong_to(:iss_reference_site).with_foreign_key('site_id').required }
    it { is_expected.to belong_to(:iss_reference_building).with_foreign_key('building_id').required }
    it { is_expected.to belong_to(:iss_reference_room).with_foreign_key('room_id').required }
    it { is_expected.to have_one(:warehouse_item).with_foreign_key('location_id').class_name('Warehouse::Item') }
  end
end
