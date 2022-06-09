require 'feature_helper'

RSpec.describe Binder, type: :model do
  it { is_expected.to belong_to(:invent_item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
  it { is_expected.to belong_to(:warehouse_item).class_name('Warehouse::Item').with_foreign_key('warehouse_item_id') }
  it { is_expected.to belong_to(:sign).class_name('Sign').with_foreign_key('sign_id').required }
end
