require 'feature_helper'

module Warehouse
  RSpec.describe Binder, type: :model do
    it { is_expected.to belong_to(:item).class_name('Warehouse::Item').with_foreign_key('warehouse_item_id').required }
    it { is_expected.to belong_to(:sign).class_name('Invent::Sign').with_foreign_key('sign_id').required }
  end
end
