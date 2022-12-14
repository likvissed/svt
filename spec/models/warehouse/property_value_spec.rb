require 'feature_helper'

module Warehouse
  RSpec.describe PropertyValue, type: :model do
    it { is_expected.to belong_to(:item).with_foreign_key('warehouse_item_id').required }
    it { is_expected.to belong_to(:property).class_name('Invent::Property').with_foreign_key('property_id').required }
    it { is_expected.to validate_presence_of(:value) }
  end
end
